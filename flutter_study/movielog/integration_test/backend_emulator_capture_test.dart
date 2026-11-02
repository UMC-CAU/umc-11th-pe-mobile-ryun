import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/main.dart' as app;
import 'package:movielog/router/app_router.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실제 Android 앱과 실제 백엔드의 미션 화면 촬영', (tester) async {
    // Production app, production routes and real HTTP; no service mocks.
    AppRouter.router.go('/my');
    await app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    binding.reportData = <String, dynamic>{
      'platform': 'Android emulator',
      'backend': const String.fromEnvironment('BACKEND_URL'),
      'realBackend': true,
      'physicalWidth': tester.view.physicalSize.width,
      'physicalHeight': tester.view.physicalSize.height,
      'devicePixelRatio': tester.view.devicePixelRatio,
    };

    Future<void> settle() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 150),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 40),
      );
    }

    Future<void> capture(String name) async {
      await settle();
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(name);
    }

    await capture('00-profile-entry');
    await tester.tap(find.text('내 평점 보기'));
    await settle();
    expect(find.text('영화 #155'), findsOneWidget);
    expect(find.text('영화 #550'), findsOneWidget);
    await capture('03-ratings');

    await tester.tap(find.byKey(const Key('ratingsPageSize')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1개').last);
    await settle();
    expect(find.text('1 / 2 페이지'), findsOneWidget);
    expect(find.text('영화 #155'), findsOneWidget);
    expect(find.text('영화 #550'), findsNothing);
    await capture('04-page-0');

    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await settle();
    expect(find.text('2 / 2 페이지'), findsOneWidget);
    expect(find.text('영화 #550'), findsOneWidget);
    expect(find.text('영화 #155'), findsNothing);
    await capture('05-page-1');

    await tester.enterText(find.byKey(const Key('ratingsMemberId')), '999');
    await tester.tap(find.text('조회'));
    await settle();
    expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);
    await capture('06-member-not-found');

    AppRouter.router.go('/register');
    await settle();
    await tester.enterText(find.byKey(const Key('nicknameField')), '수현');
    await tester.ensureVisible(find.text('닉네임 중복 확인'));
    await tester.tap(find.text('닉네임 중복 확인'));
    await settle();
    await tester.enterText(find.byKey(const Key('emailField')), 'noco@umc.com');
    await tester.ensureVisible(find.text('이메일 중복 확인'));
    await tester.tap(find.text('이메일 중복 확인'));
    await settle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 900));
    await capture('01-duplicates');

    await tester.enterText(find.byKey(const Key('nicknameField')), '새닉네임');
    await tester.ensureVisible(find.text('닉네임 중복 확인'));
    await tester.tap(find.text('닉네임 중복 확인'));
    await settle();
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'new@example.com',
    );
    await tester.ensureVisible(find.text('이메일 중복 확인'));
    await tester.tap(find.text('이메일 중복 확인'));
    await settle();
    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
    expect(find.text('사용 가능한 이메일입니다.'), findsOneWidget);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 900));
    await capture('02-available');

    await tester.enterText(find.byKey(const Key('nicknameField')), 'a');
    await tester.enterText(find.byKey(const Key('emailField')), 'not-an-email');
    await settle();
    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 900));
    await capture('09-validation');

    AppRouter.router.go('/my/ratings');
    await settle();
    expect(find.text('영화 #155'), findsOneWidget);
    expect(find.text('영화 #550'), findsOneWidget);
    binding.reportData!['verifiedScreens'] = 8;
  });
}
