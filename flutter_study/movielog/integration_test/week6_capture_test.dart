import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';

class CaptureChecks extends MemberCheckService {
  CaptureChecks() : super(createMovieLogClient());
  bool fixture = false;
  Completer<bool>? pending;
  Completer<bool>? emailPending;
  @override
  Future<bool> checkNickname(String value) =>
      pending?.future ??
      (fixture ? Future.value(false) : super.checkNickname(value));
  @override
  Future<bool> checkEmail(String value) =>
      emailPending?.future ??
      (fixture ? Future.value(false) : super.checkEmail(value));
}

class CaptureRatings extends RatingApiService {
  CaptureRatings() : super(createMovieLogClient());
  String mode = 'real';
  Completer<List<RatingDto>>? pending;
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) {
    if (mode == 'hold') return pending!.future;
    if (mode == 'empty') return Future.value([]);
    if (mode == 'error') throw DioException(requestOptions: RequestOptions());
    return super.fetchMyRatings(memberId);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('W6 real API and explicitly labelled state fixtures', (
    tester,
  ) async {
    await dotenv.load(fileName: '.env');
    final checks = CaptureChecks();
    final ratings = CaptureRatings();
    final captureKey = GlobalKey();
    AppRouter.router.go('/my');
    runApp(
      RepaintBoundary(
        key: captureKey,
        child: MovieLogApp(
          memberCheckService: checks,
          ratingApiService: ratings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      // Let the native keyboard finish its inset animation before painting.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (i >= 2 && tester.view.viewInsets.bottom == 0) {
          break;
        }
      }
      expect(tester.takeException(), isNull);
      // Read the whole Flutter render layer: Android surface screenshots can
      // inherit a stale translation after keyboard/route transitions.
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      void repaint(RenderObject object) {
        object.visitChildren(repaint);
        object.markNeedsPaint();
      }

      repaint(boundary);
      await tester.pump();
      final rendered = await boundary.toImage(
        pixelRatio: tester.view.devicePixelRatio,
      );
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      binding.reportData ??= <String, dynamic>{};
      final screens = binding.reportData!.putIfAbsent(
        'renderedScreens',
        () => <String, dynamic>{},
      ) as Map<String, dynamic>;
      screens[name] = base64Encode(bytes!.buffer.asUint8List());
      rendered.dispose();
      debugPrint('W6 captured: $name');
      for (final title in ['회원가입', '내가 등록한 평점', '내 프로필']) {
        final finder = find.text(title);
        if (finder.evaluate().length == 1) {
          debugPrint(
            'W6 layout $name $title ${tester.getRect(finder)} topInset=${tester.view.padding.top}',
          );
        }
      }
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 400 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(finder, findsWidgets);
      await tester.pumpAndSettle();
    }

    await capture('00-real-profile');
    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pump(const Duration(milliseconds: 100));
    await capture('01-real-ratings-loading');
    await waitFor(find.byKey(const Key('rating-1')));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('코멘트가 없습니다.'), findsNothing);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pumpAndSettle();
    await capture('02-real-ratings-success');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('내가 등록한 평점'), findsOneWidget);
    AppRouter.router.go('/register');
    await tester.pumpAndSettle();
    await capture('03-register-idle');
    await tester.enterText(find.byKey(const Key('nicknameField')), 'week6새닉네임');
    await tester.pump();
    checks.pending = Completer<bool>();
    await tester.tap(find.byKey(const Key('nicknameCheckButton')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await capture('04-fixture-checking');
    checks.pending!.complete(true);
    checks.pending = null;
    await tester.pumpAndSettle();
    // Real requests: both fields use v5. The held request above only proves spinner UI.
    await tester.enterText(
      find.byKey(const Key('nicknameField')),
      'week6새닉네임2',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('nicknameCheckButton')));
    await waitFor(find.text('사용 가능한 닉네임입니다.'));
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'week6-new@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('emailCheckButton')));
    await waitFor(find.text('사용 가능한 이메일입니다.'));
    await capture('05-real-available');
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password1234',
    );
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 1000),
    );
    await tester.pumpAndSettle();
    checks.emailPending = Completer<bool>();
    await tester.tap(find.byKey(const Key('emailCheckButton')));
    await tester.pump();
    expect(find.text('이메일 사용 가능 여부를 확인 중입니다.'), findsOneWidget);
    await capture('12-figma-signup-email-loading');
    checks.emailPending!.complete(true);
    checks.emailPending = null;
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nicknameField')), 'week6중복');
    await tester.pump();
    checks.fixture = true;
    await tester.tap(find.byKey(const Key('nicknameCheckButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'duplicate@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('emailCheckButton')));
    await tester.pumpAndSettle();
    await capture('06-fixture-duplicated');
    await tester.enterText(find.byKey(const Key('nicknameField')), '다른닉네임');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'changed@example.com',
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
    await capture('07-results-invalidated');
    await tester.enterText(find.byKey(const Key('nicknameField')), 'week6중복');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'duplicate@example.com',
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    await capture('08-duplicate-recalled');
    ratings.mode = 'empty';
    AppRouter.router.go('/my/ratings');
    await tester.pumpAndSettle();
    expect(find.text('아직 등록한 평점이 없습니다.'), findsOneWidget);
    await capture('09-fixture-ratings-empty');
    AppRouter.router.go('/my');
    await tester.pumpAndSettle();
    ratings.mode = 'error';
    AppRouter.router.go('/my/ratings');
    await tester.pumpAndSettle();
    await capture('10-fixture-ratings-error');
    ratings.mode = 'real';
    await tester.tap(find.text('다시 시도'));
    await waitFor(find.byKey(const Key('rating-1')));
    await capture('11-real-retry-success');
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!.addAll({
      'realServer': 'https://workbook.devnoco.com/v5',
      'fixtureScreens': ['04', '06', '08', '09', '10', '12'],
      'note': 'Fixture states use injected services; real success uses v5 and TMDB.',
    });
  });
}
