import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/config/study_config.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/session/auth_session.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/login_screen.dart';
import 'package:movielog/home/home_screen.dart';
import 'package:movielog/movie/widgets/tmdb_movie_card.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/profile/my_ratings_screen.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const restart = bool.fromEnvironment('WEEK8_RESTORE_ONLY');
  testWidgets(
    'Week 8 v7 Android evidence',
    (tester) async {
      expect(week8, true);
      await dotenv.load(fileName: '.env');
      final public = createMovieLogClient();
      final storage = SecureTokenStorage(key: 'movielog.week8.evidence');
      final session = AuthSession(public, storage)..initialized = !restart;
      final auth = createMovieLogClient()
        ..interceptors.add(AuthInterceptor(session));
      final tmdb = createTmdbClient();
      final movies = TmdbMovieService(tmdb);
      final ratings = RatingApiService(
        auth,
        authenticated: true,
        publicClient: public,
        sessionVersion: () => session.generation,
      );
      final signup = SignUpService(public, version: 'v7');
      final trace = <String>[];
      final checks = <String>[];
      final screens = <String, String>{};
      binding.reportData = {
        'renderedScreens': screens,
        'apiTrace': trace,
        'assertions': checks,
        'platform': 'Android emulator-5554',
        'restartProcess': restart,
        'studyWeek': 8,
      };
      bool failMe = false;
      bool failPatch = false;
      bool holdMe = false;
      Completer<void>? meGate;
      for (final dio in [public, auth]) {
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) async {
              if (r.path == '/v7/members/me' && r.method == 'GET' && holdMe) {
                await meGate!.future;
              }
              if ((failMe && r.method == 'GET' ||
                      failPatch && r.method == 'PATCH') &&
                  r.path == '/v7/members/me') {
                failMe = false;
                failPatch = false;
                trace.add('fixture: ${r.method} ${r.path} connection failure');
                h.reject(
                  DioException(
                    requestOptions: r,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              h.next(r);
            },
            onResponse: (r, h) {
              trace.add(
                'live: ${r.requestOptions.method} ${r.requestOptions.path} -> ${r.statusCode}',
              );
              h.next(r);
            },
            onError: (e, h) {
              trace.add(
                'live/error: ${e.requestOptions.method} ${e.requestOptions.path} -> ${e.response?.statusCode ?? e.type.name}',
              );
              h.next(e);
            },
          ),
        );
      }
      final key = GlobalKey();
      void app() => runApp(
        RepaintBoundary(
          key: key,
          child: MovieLogApp(
            authSession: session,
            movieService: movies,
            ratingApiService: ratings,
            signUpService: signup,
            profileClient: auth,
          ),
        ),
      );
      Future<void> hold([int seconds = 1]) async {
        for (var i = 0; i < seconds * 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
        }
      }

      Future<void> until(bool Function() ready, String label) async {
        for (var i = 0; i < 300; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          if (ready()) return;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
        }
        throw StateError('Timeout: $label');
      }

      Future<void> gate(String stage, bool start) async {
        final suffix = start ? 'started' : 'stopped';
        final file = File('${Directory.systemTemp.path}/week8-$stage-$suffix');
        if (await file.exists()) await file.delete();
        debugPrint(
          'W8_VIDEO_${start ? 'READY' : 'DONE'}:$stage:${Directory.systemTemp.path}',
        );
        await until(file.existsSync, 'host $suffix');
        await hold();
      }

      Future<void> capture(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await hold();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('favoriteButton')), findsNothing);
        expect(find.text('즐겨찾기에도 추가'), findsNothing);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        void repaint(RenderObject o) {
          o.visitChildren(repaint);
          o.markNeedsPaint();
        }

        repaint(boundary);
        await tester.pump();
        final img = await boundary.toImage(
          pixelRatio: tester.view.devicePixelRatio,
        );
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        screens[name] = base64Encode(bytes!.buffer.asUint8List());
        img.dispose();
        debugPrint('W8 capture: $name');
      }

      Future<void> enter(Finder f, String text) async {
        tester.widget<TextField>(f).controller!.text = text;
        await tester.pump();
      }

      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pump();
        await tester.tap(f);
        await hold();
      }

      Future<void> route(String path) async {
        AppRouter.router.go(path);
        await hold();
      }

      MyRatingsViewModel ratingModel() => tester
          .element(find.byType(MyRatingsScreen))
          .read<MyRatingsViewModel>();
      if (const bool.fromEnvironment('WEEK8_SEED_ONLY')) {
        final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
        final password = 'W8s!${Random.secure().nextInt(1 << 30)}X';
        final email = 'w8restart$nonce@example.invalid';
        await signup.signUp(
          CreateMemberRequest(
            email: email,
            password: password,
            nickname: '복원${nonce.substring(nonce.length - 6)}',
          ),
        );
        await session.login(email, password);
        expect(await storage.read(), isNotNull);
        checks.add(
          'Seed process: live login -> Android secure storage write/read; no credentials exported',
        );
        app();
        await route('/my');
        await capture('r00-seed-process-signed-in');
        return;
      }
      if (restart) {
        expect(await storage.read(), isNotNull);
        AppRouter.router.go('/initializing');
        app();
        await hold();
        await capture('r01-process-restarted-session-check');
        await gate('restart', true);
        holdMe = true;
        meGate = Completer<void>();
        final task = session.restore();
        await hold();
        await capture('r02-secure-storage-verifying');
        meGate.complete();
        await task;
        holdMe = false;
        await route('/home');
        await until(
          () => find.byType(HomeScreen).evaluate().isNotEmpty,
          'home',
        );
        await capture('r03-verified-home');
        await route('/my');
        await capture('r04-restored-member');
        checks.add(
          'NEW Android app process: secure storage read -> live GET /v7/members/me 200 -> home and same member',
        );
        await gate('restart', false);
        holdMe = true;
        meGate = Completer<void>();
        final loading = session.loadMember();
        await hold();
        await capture('r06-member-full-loading');
        expect(session.memberStatus, MemberLoadStatus.loading);
        meGate.complete();
        await loading;
        holdMe = false;
        failMe = true;
        await session.loadMember();
        await hold();
        await capture('r07-fixture-member-error');
        expect(session.authenticated, true);
        await tap(find.text('다시 시도'));
        await until(
          () => session.memberStatus == MemberLoadStatus.ready,
          'member retry',
        );
        await capture('r08-live-member-retry');
        checks.add(
          'Challenge full-screen member loading/error/retry; network error preserves authentication',
        );
        await session.logout();
        expect(await storage.read(), isNull);
        checks.add('Android secure storage delete verified');
      } else {
        await storage.write(null);
        final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
        final password = 'W8a!${Random.secure().nextInt(1 << 30)}X';
        final email = 'w8$nonce@example.invalid';
        final nick = 'w8${nonce.substring(nonce.length - 7)}';
        final updated = '기록${nonce.substring(nonce.length - 6)}';
        final retryName = '재시도${nonce.substring(nonce.length - 6)}';
        final duplicate = 'd8${nonce.substring(nonce.length - 7)}';
        await signup.signUp(
          CreateMemberRequest(email: email, password: password, nickname: nick),
        );
        await signup.signUp(
          CreateMemberRequest(
            email: 'd8$nonce@example.invalid',
            password: password,
            nickname: duplicate,
          ),
        );
        AppRouter.router.go('/login');
        app();
        await hold();
        await gate('login-profile', true);
        await enter(find.byKey(const Key('loginEmail')), email);
        await enter(find.byKey(const Key('loginPassword')), 'WrongPassword8!');
        await tap(find.widgetWithText(ElevatedButton, '로그인'));
        await until(
          () =>
              find.textContaining('이메일 또는').evaluate().isNotEmpty ||
              (!session.busy && !session.authenticated),
          'login fail',
        );
        await capture('a01-live-login-401-form-error');
        expect(session.sessionExpired, false);
        tester
                .widget<TextField>(find.byKey(const Key('loginPassword')))
                .controller!
                .text =
            password;
        await tester.pump();
        await tap(find.text('이메일 저장'));
        await tap(find.widgetWithText(ElevatedButton, '로그인'));
        await until(() => session.authenticated, 'login success');
        await route('/my');
        await capture('a02-live-login-member');
        expect(await storage.read(), isNotNull);
        await tap(find.text('프로필 수정'));
        await enter(find.byKey(const Key('profileNickname')), updated);
        await tap(find.text('저장'));
        await until(() => session.nickname == updated, 'nickname saved');
        await capture('a03-live-nickname-updated');
        await tap(find.text('프로필 수정'));
        await enter(find.byKey(const Key('profileNickname')), duplicate);
        await tap(find.text('저장'));
        await until(
          () => find.textContaining('이미').evaluate().isNotEmpty,
          'duplicate 409',
        );
        await capture('a04-live-nickname-409-retained');
        expect(session.authenticated, true);
        await enter(find.byKey(const Key('profileNickname')), 'a');
        await tap(find.text('저장'));
        await capture('a05-nickname-length-error');
        await enter(find.byKey(const Key('profileNickname')), retryName);
        failPatch = true;
        await tap(find.text('저장'));
        await capture('a06-fixture-profile-network-error');
        expect(session.authenticated, true);
        await tap(find.byIcon(Icons.arrow_back));
        await capture('a07-unsaved-changes-dialog');
        await tap(find.text('계속 수정'));
        await tap(find.text('저장'));
        await until(() => session.nickname == retryName, 'retry nickname');
        await capture('a08-live-profile-retry-success');
        await gate('login-profile', false);
        checks.add(
          'Live login AUTH401_1 + success, GET me, PATCH nickname success/409; validation, fixture connection failure, retry, dirty back dialog',
        );
        await route('/movies');
        await until(
          () => find.byType(TmdbMovieCard).evaluate().isNotEmpty,
          'movie list',
        );
        await capture('b00-week8-movies-no-search');
        await tap(find.byType(TmdbMovieCard).first);
        await capture('b01-week8-detail-no-bookmark');
        await gate('rating-crud', true);
        await tap(find.text('평점 남기기'));
        tester.widget<RatingBar>(find.byType(RatingBar)).onRatingUpdate(4);
        await tester.pump();
        await enter(
          find.byKey(const Key('ratingCommentField')),
          '8주차 토큰 기반 평점 실습',
        );
        await capture('b02-rating-input-no-favorite-checkbox');
        await tap(find.byKey(const Key('ratingConfirmButton')));
        await until(
          () => find.text('평점을 저장했습니다.').evaluate().isNotEmpty,
          'create rating',
        );
        await capture('b03-live-rating-created');
        await route('/my/ratings');
        await until(
          () => ratingModel().status == MyRatingsLoadStatus.success,
          'ratings list',
        );
        await capture('b04-current-session-rating');
        await tap(find.text('수정'));
        await capture('b05-edit-score-comment-prefilled');
        tester.widget<RatingBar>(find.byType(RatingBar)).onRatingUpdate(5);
        await tester.pump();
        await enter(find.byKey(const Key('ratingCommentField')), '8주차 수정 완료');
        await tap(find.byKey(const Key('ratingConfirmButton')));
        await until(
          () => find.text('8주차 수정 완료').evaluate().isNotEmpty,
          'patch rating',
        );
        await capture('b06-live-rating-updated');
        await tap(find.text('삭제'));
        await capture('b07-delete-confirm');
        await tap(find.text('삭제').last);
        await until(
          () => ratingModel().status == MyRatingsLoadStatus.empty,
          'delete rating',
        );
        await capture('b08-live-rating-deleted');
        await gate('rating-crud', false);
        checks.add(
          'Live v7 rating POST 201, PATCH 200 with score/comment, DELETE 200; no memberId in write path/body',
        );
        await gate('session-security', true);
        failMe = true;
        await session.restore();
        await hold();
        await capture('c01-fixture-restore-network-retry');
        expect(await storage.read(), isNotNull);
        expect(session.restoreFailed, true);
        await tap(find.text('다시 시도'));
        await until(() => session.authenticated, 'restore retry');
        await route('/my');
        await capture('c02-live-restore-retry-success');
        // Real invalid-token response, never log or show the value.
        await storage.write('invalid-test-token');
        await session.restore();
        await hold();
        await capture('c03-live-invalid-token-login-snackbar');
        expect(session.authenticated, false);
        expect(await storage.read(), isNull);
        await session.login(email, password);
        await route('/my');
        await tap(find.widgetWithText(TextButton, '로그아웃'));
        await capture('c04-logout-login');
        expect(await storage.read(), isNull);
        for (final path in ['/my', '/my/profile/edit', '/my/ratings']) {
          await route(path);
          expect(find.byType(LoginScreen), findsOneWidget);
        }
        await capture('c05-protected-route-blocked');
        await gate('session-security', false);
        checks.add(
          'Restore connection failure preserves token and retry succeeds; live invalid token AUTH401_3 deletes token + Snackbar; logout blocks /my, /my/profile/edit, /my/ratings',
        );
        await session.login(email, password);
        await route('/my');
        checks.add(
          'Valid secure storage token intentionally retained for separate-process restart verification',
        );
      }
      // Study preview, separate from product UI. Only sanitized method/path/status are displayed.
      runApp(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              appBar: AppBar(title: const Text('8주차 · 인증 통신 검증 기록')),
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    const Text(
                      '실제 Android 실행 · 민감값 제외\nJWT / Authorization / 비밀번호 / 요청 body 미표시\nfixture는 오류 재현용 주입임\n',
                    ),
                    ...trace
                        .take(20)
                        .map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(line),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await hold();
      await capture(
        restart ? 'r05-sanitized-restart-log' : 's01-sanitized-api-log',
      );
      expect(trace.any((line) => line.contains('/v8/')), false);
      checks.add(
        'No v8 API calls, no bookmark or combined-save controls in all captured frames',
      );
      public.close(force: true);
      auth.close(force: true);
      tmdb.close(force: true);
    },
    skip: !const bool.fromEnvironment('WEEK8_CAPTURE_LIVE'),
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
