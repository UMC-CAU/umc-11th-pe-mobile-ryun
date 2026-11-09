import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/register_screen.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:provider/provider.dart';

import 'week7_test.dart' show envelope, fakeWorkbook;

import 'package:movielog/common/movie_log_text_form_field.dart';

void main() {
  Widget buildSubject() {
    return MaterialApp(
      home: RegisterScreen(
        memberService: SignUpService(
          fakeWorkbook((_) => (200, {'available': true})),
        ),
      ),
    );
  }

  testWidgets('회원가입 화면의 필수 입력 요소를 표시한다', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byKey(const Key('nicknameField')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('termsCheckbox')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('registerButton')),
        matching: find.byType(ElevatedButton),
      ),
      findsOneWidget,
    );
    expect(find.byType(MovieLogTextFormField), findsNWidgets(3));
  });

  testWidgets('비밀번호 표시 버튼으로 입력값을 표시하고 다시 숨긴다', (tester) async {
    await tester.pumpWidget(buildSubject());

    final passwordField = find.byKey(const Key('passwordField'));
    final visibilityButton = find.byKey(const Key('passwordVisibilityButton'));

    EditableText passwordInput = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(passwordInput.obscureText, isTrue);

    await tester.ensureVisible(visibilityButton);
    await tester.pumpAndSettle();
    await tester.tap(visibilityButton);
    await tester.pump();

    passwordInput = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(passwordInput.obscureText, isFalse);

    await tester.ensureVisible(visibilityButton);
    await tester.pumpAndSettle();
    await tester.tap(visibilityButton);
    await tester.pump();

    passwordInput = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(passwordInput.obscureText, isTrue);
  });

  testWidgets('너비 700 이상에서는 Form 최대 너비를 560으로 제한한다', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());

    expect(tester.getSize(find.byType(Form)).width, 560);
    expect(tester.getCenter(find.byType(Form)).dx, 600);
  });

  testWidgets('잘못된 입력에 한국어 오류 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.enterText(find.byKey(const Key('nicknameField')), 'a');
    await tester.enterText(find.byKey(const Key('emailField')), 'test@');
    await tester.enterText(find.byKey(const Key('passwordField')), '123');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('모든 조건이 유효할 때 가입 버튼을 활성화한다', (tester) async {
    await tester.pumpWidget(buildSubject());

    ElevatedButton button = tester.widget(
      find.descendant(
        of: find.byKey(const Key('registerButton')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('nicknameField')), '무비러버');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'movie@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'Study1234!',
    );
    await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pump();

    button = tester.widget(
      find.descendant(
        of: find.byKey(const Key('registerButton')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
    for (final key in ['nicknameCheckButton', 'emailCheckButton']) {
      final check = find.byKey(Key(key));
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
    }
    button = tester.widget(
      find.descendant(
        of: find.byKey(const Key('registerButton')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('작은 화면에서도 스크롤해 가입 버튼에 접근할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('registerButton')),
        matching: find.byType(ElevatedButton),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('스크롤은 Focus를 유지하고 바깥 탭은 Focus를 해제한다', (tester) async {
    await tester.pumpWidget(buildSubject());

    final nicknameField = find.byKey(const Key('nicknameField'));
    await tester.tap(nicknameField);
    await tester.pump();

    EditableText editableText = tester.widget(
      find.descendant(of: nicknameField, matching: find.byType(EditableText)),
    );
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pump();

    editableText = tester.widget(
      find.descendant(of: nicknameField, matching: find.byType(EditableText)),
    );
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(20, 200));
    await tester.pump();

    expect(editableText.focusNode.hasFocus, isFalse);
  });

  testWidgets('가입 요청 중 이탈을 막고 성공 시 memberId를 저장한 뒤 영화 목록으로 이동한다', (
    tester,
  ) async {
    final pending = Completer<(int, Object?)>();
    var submits = 0;
    final service = SignUpService(
      fakeWorkbook((request) {
        if (request.method == 'GET') return (200, {'available': true});
        if (submits++ == 0) {
          return (400, envelope(400, '비밀번호 형식을 확인해 주세요.'));
        }
        return pending.future;
      }),
    );
    final session = LearningMemberSession();
    addTearDown(session.dispose);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('시작'),
            ),
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (_, _) => RegisterScreen(memberService: service),
        ),
        GoRoute(
          path: '/movies',
          builder: (_, _) => const Scaffold(body: Text('영화 테스트 화면')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('시작'));
    await tester.pumpAndSettle();
    for (final (key, text) in [
      ('nicknameField', '무비러버'),
      ('emailField', 'movie@example.com'),
      ('passwordField', 'Study1234!'),
    ]) {
      await tester.enterText(find.byKey(Key(key)), text);
      await tester.pump();
    }
    for (final key in [
      'nicknameCheckButton',
      'emailCheckButton',
      'termsCheckbox',
    ]) {
      final control = find.byKey(Key(key));
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
    }
    final submit = find.byKey(const Key('registerButton'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('비밀번호 형식을 확인해 주세요.'), findsOneWidget);
    final password = find.byKey(const Key('passwordField'));
    await tester.ensureVisible(password);
    await tester.enterText(password, 'Study2345!');
    await tester.pumpAndSettle();
    expect(find.text('비밀번호 형식을 확인해 주세요.'), findsNothing);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(session.memberId, isNull);
    pending.complete((
      201,
      envelope(201, '가입', {
        'memberId': 42,
        'nickname': '무비러버',
        'email': 'movie@example.com',
      }),
    ));
    await tester.pumpAndSettle();
    expect(session.memberId, 42);
    expect(find.text('영화 테스트 화면'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });
}
