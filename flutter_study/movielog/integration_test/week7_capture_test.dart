import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie/widgets/tmdb_movie_card.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const live = bool.fromEnvironment('WEEK7_CAPTURE_LIVE');
  const requiredMission = bool.fromEnvironment('WEEK7_REQUIRED');
  const challengeMission = bool.fromEnvironment('WEEK7_CHALLENGE');
  testWidgets(
    'Week 7 Guided A/B and rating write/read on Android',
    (tester) async {
      await dotenv.load(fileName: '.env');
      final dio = createMovieLogClient();
      final tmdb = createTmdbClient();
      final trace = <String>[];
      final screens = <String, String>{};
      binding.reportData = {'renderedScreens': screens, 'apiTrace': trace};
      var staleAvailability = false;
      var failNextGet = false;
      var sentAuthorization = false;
      String? signUp400;
      Completer<void>? pendingSignUp;
      Completer<void>? pendingDeletes;
      int? failDeleteId;
      final deleteRequests = <String>[];
      final conflicts = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final path = options.path;
            // Assertions run in the test body, outside the network callback.
            sentAuthorization |= options.headers.keys.any(
              (key) => key.toLowerCase() == 'authorization',
            );
            if (options.method == 'POST' && path == '/v6/members') {
              final message = signUp400;
              if (message != null) {
                signUp400 = null;
                trace.add('fixture: sign-up 400');
                final response = Response<dynamic>(
                  requestOptions: options,
                  statusCode: 400,
                  data: {
                    'isSuccess': false,
                    'code': 'COMMON400',
                    'message': message,
                    'result': null,
                  },
                );
                handler.reject(
                  DioException.badResponse(
                    statusCode: 400,
                    requestOptions: options,
                    response: response,
                  ),
                );
                return;
              }
              await pendingSignUp?.future;
            }
            if (options.method == 'DELETE') {
              deleteRequests.add(path);
              await pendingDeletes?.future;
              if (failDeleteId != null && path.endsWith('/$failDeleteId')) {
                trace.add('fixture: DELETE 403 for selected rating');
                handler.reject(
                  DioException.badResponse(
                    statusCode: 403,
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 403,
                    ),
                  ),
                );
                return;
              }
            }
            if (staleAvailability &&
                (path.contains('/nickname/') || path.contains('/email/'))) {
              trace.add('fixture: stale available=true');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'available': true},
                ),
              );
            } else if (failNextGet &&
                options.method == 'GET' &&
                path.endsWith('/ratings')) {
              failNextGet = false;
              trace.add('fixture: failed ratings GET');
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
            } else {
              handler.next(options);
            }
          },
          onResponse: (response, handler) {
            final request = response.requestOptions;
            final path = request.path;
            final safePath =
                path.contains('/email/') || path.contains('/nickname/')
                ? path.substring(0, path.lastIndexOf('/'))
                : path;
            trace.add('${request.method} $safePath ${response.statusCode}');
            handler.next(response);
          },
          onError: (error, handler) {
            trace.add(
              '${error.requestOptions.method} ${error.response?.statusCode ?? 'network'}',
            );
            if (error.requestOptions.method == 'GET' &&
                error.requestOptions.path.endsWith('/ratings') &&
                error.response == null) {
              trace.add(
                'GET ratings error: ${error.type.name} (${error.error.runtimeType})',
              );
            }
            if (error.response?.statusCode == 409) {
              conflicts.add(error.requestOptions.path);
            }
            handler.next(error);
          },
        ),
      );
      final key = GlobalKey();
      AppRouter.router.go('/register');
      runApp(
        RepaintBoundary(
          key: key,
          child: MovieLogApp(
            movieService: TmdbMovieService(tmdb),
            signUpService: SignUpService(dio),
            ratingApiService: RatingApiService(dio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 180; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (finder.evaluate().isNotEmpty) return;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 125)),
          );
        }
        expect(finder, findsWidgets, reason: 'Safe API trace: $trace');
      }

      Future<void> capture(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        for (var i = 0; i < 7; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 65)),
          );
          await tester.pump(const Duration(milliseconds: 60));
          if (i >= 4 && tester.view.viewInsets.bottom == 0) break;
        }
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        void repaint(RenderObject object) {
          object.visitChildren(repaint);
          object.markNeedsPaint();
        }

        repaint(boundary);
        await tester.pump();
        final render = await boundary.toImage(
          pixelRatio: tester.view.devicePixelRatio,
        );
        final png = await render.toByteData(format: ui.ImageByteFormat.png);
        screens[name] = base64Encode(png!.buffer.asUint8List());
        render.dispose();
        debugPrint('W7 captured: $name');
      }

      Finder keyed(String value) => find.byKey(Key(value));
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pump();
        await tester.tap(finder);
        await tester.pump();
      }

      final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final email = 'movielog.w7.$suffix@example.com';
      final nickname = 'W7$suffix';
      final password = 'Wk7!${Random.secure().nextInt(1 << 30)}';
      Future<void> fillSignUp() async {
        await tester.enterText(keyed('nicknameField'), nickname);
        await tester.pump();
        await tap(keyed('nicknameCheckButton'));
        await waitFor(find.text('사용 가능한 닉네임입니다.'));
        await tester.enterText(keyed('emailField'), email);
        await tester.pump();
        await tap(keyed('emailCheckButton'));
        await waitFor(find.text('사용 가능한 이메일입니다.'));
        await tester.enterText(keyed('passwordField'), password);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 350));
        await tap(keyed('termsCheckbox'));
      }

      await fillSignUp();
      await capture('a01-checks-passed');
      if (requiredMission) {
        signUp400 = '비밀번호 형식을 확인해 주세요.';
        await tap(keyed('registerButton'));
        await waitFor(find.text('비밀번호 형식을 확인해 주세요.'));
        expect(find.byType(SnackBar), findsNothing);
        await capture('r01-fixture-password-400');
        AppRouter.router.go('/start');
        await tester.pumpAndSettle();
        AppRouter.router.go('/register');
        await tester.pumpAndSettle();
        await fillSignUp();
        signUp400 = '회원 입력값을 확인해 주세요.';
        await tap(keyed('registerButton'));
        await waitFor(find.widgetWithText(SnackBar, '회원 입력값을 확인해 주세요.'));
        await capture('r02-fixture-other-400');
        ScaffoldMessenger.of(tester.element(keyed('registerButton')))
            .removeCurrentSnackBar();
        pendingSignUp = Completer<void>();
      }
      await tap(keyed('registerButton'));
      if (requiredMission) {
        await waitFor(find.byType(CircularProgressIndicator));
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(keyed('registerButton'), findsOneWidget);
        expect(
          tester.widget<MovieLogButton>(keyed('registerButton')).isLoading,
          isTrue,
        );
        await capture('r03-signup-submitting-back-blocked');
        pendingSignUp!.complete();
      }
      await waitFor(find.textContaining('회원가입을 완료했습니다.'));
      await waitFor(find.byType(TmdbMovieCard));
      final memberId = tester
          .element(find.byType(TmdbMovieCard).first)
          .read<LearningMemberSession>()
          .memberId!;
      binding.reportData!['memberId'] = memberId;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 850)),
      );
      await capture('a02-live-signup-201');
      expect(trace, contains('POST /v6/members 201'));
      ScaffoldMessenger.of(tester.element(find.byType(TmdbMovieCard).first))
          .removeCurrentSnackBar();
      await tester.pump(const Duration(milliseconds: 350));

      await tap(find.byType(TmdbMovieCard).first);
      await waitFor(find.text('평점 남기기'));
      await tester.pump(const Duration(milliseconds: 400));
      debugPrint('W7 video start');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MovieLogButton>(keyed('ratingConfirmButton')).onPressed,
        isNull,
      );
      await capture('b01-no-score-confirm-disabled');
      Future<void> selectScore(int score) async {
        final bar = tester.getRect(find.byType(RatingBar));
        await tester.tapAt(
          Offset(bar.left + (score - 0.5) * bar.width / 5, bar.center.dy),
        );
        await tester.pump();
      }

      await selectScore(4);
      const firstComment = '인상적인 연출이 오래 기억에 남아요.';
      await tester.enterText(keyed('ratingCommentField'), firstComment);
      await capture('b02-score-and-comment');
      await tap(keyed('ratingConfirmButton'));
      await waitFor(find.textContaining('평점을 등록했습니다.'));
      await capture('b03-live-create-201');
      expect(
        trace.any(
          (line) => RegExp(r'POST /v6/members/\d+/ratings 201').hasMatch(line),
        ),
        isTrue,
      );
      ScaffoldMessenger.of(tester.element(find.text('평점 남기기')))
          .removeCurrentSnackBar();
      await tester.pump(const Duration(milliseconds: 350));

      // Second rating POST to the same new account/movie receives the real server's 409.
      await tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      await selectScore(3);
      const unsaved = '저장에 실패해도 이 입력은 유지됩니다.';
      await tester.enterText(keyed('ratingCommentField'), unsaved);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 350));
      await tap(keyed('ratingConfirmButton'));
      await waitFor(find.textContaining('이미 이 영화에'));
      expect(
        tester.widget<TextField>(keyed('ratingCommentField')).controller!.text,
        unsaved,
      );
      await capture('b04-live-409-input-retained');
      await tap(find.text('취소'));
      await tester.pump(const Duration(milliseconds: 500));

      final api = RatingApiService(dio);
      if (challengeMission) {
        final original = (await api.fetchMyRatings(memberId)).single;
        final movieIds = [
          155,
          550,
          27205,
        ].where((id) => id != original.movieId).take(2);
        for (final id in movieIds) {
          await api.createRating(
            memberId: memberId,
            request: CreateRatingRequest(
              movieId: id,
              score: 5,
              comment: '다중 삭제 검증용 평점',
            ),
          );
        }
      }

      AppRouter.router.go('/my');
      await tester.pump(const Duration(milliseconds: 350));
      await tap(find.text('내가 등록한 평점'));
      await waitFor(find.text(firstComment));
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        tester.getCenter(find.text('수정').first).dx,
        greaterThan(tester.getCenter(find.text(firstComment)).dx),
      );
      await capture('b05-live-ratings-get');
      if (challengeMission) {
        final entries = await api.fetchMyRatings(memberId);
        expect(entries, hasLength(3));
        final first = entries[0].ratingId;
        final failed = entries[1].ratingId;
        final untouched = entries[2].ratingId;
        Finder check(int id) => keyed('select-rating-$id');
        final deleteSelected = keyed('delete-selected-ratings');
        Finder confirm(String label) => find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(label),
        );
        await capture('c01-edit-entry');
        await tap(find.text('편집'));
        expect(tester.widget<MovieLogButton>(deleteSelected).onPressed, isNull);
        expect(find.text('수정'), findsNothing);
        expect(find.text('0개 선택'), findsOneWidget);
        await capture('c02-zero-selection');
        await tap(check(first));
        await tap(check(failed));
        expect(find.text('2개 선택'), findsOneWidget);
        await capture('c03-two-selected');
        await tap(find.text('취소'));
        expect(find.byType(Checkbox), findsNothing);
        expect(deleteRequests, isEmpty);
        await capture('c04-selection-cancelled');
        await tap(find.text('편집'));
        expect(find.text('0개 선택'), findsOneWidget);
        await tap(check(first));
        await tap(check(failed));
        await tap(deleteSelected);
        await tester.pumpAndSettle();
        await capture('c05-delete-confirm');
        await tap(confirm('취소'));
        await tester.pumpAndSettle();
        expect(deleteRequests, isEmpty);
        expect(find.text('2개 선택'), findsOneWidget);

        pendingDeletes = Completer<void>();
        failDeleteId = failed;
        await tap(deleteSelected);
        await tester.pumpAndSettle();
        await tap(confirm('삭제'));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(AlertDialog), findsNothing);
        expect(keyed('delete-selection-progress'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(keyed('delete-selection-progress'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 180));
        await capture('c06-delete-overlay-back-blocked');
        pendingDeletes.complete();
        await waitFor(find.text('1개를 삭제했습니다. 1개는 삭제하지 못했습니다.'));
        expect(deleteRequests, [
          '/v6/members/$memberId/ratings/$first',
          '/v6/members/$memberId/ratings/$failed',
        ]);
        expect(keyed('rating-$first'), findsNothing);
        expect(keyed('rating-$untouched'), findsOneWidget);
        expect(tester.widget<Checkbox>(check(failed)).value, isTrue);
        await capture('c07-partial-failure');
        failDeleteId = null;
        await tap(deleteSelected);
        await tester.pumpAndSettle();
        await tap(confirm('삭제'));
        await waitFor(find.text('편집'));
        expect(keyed('rating-$failed'), findsNothing);
        expect(keyed('rating-$untouched'), findsOneWidget);
        await capture('c08-retry-success');
        ScaffoldMessenger.of(tester.element(find.text('편집')))
            .removeCurrentSnackBar();
        await tap(find.text('편집'));
        await tap(check(untouched));
        await tap(deleteSelected);
        await tester.pumpAndSettle();
        await tap(confirm('삭제'));
        await waitFor(find.text('아직 등록한 평점이 없습니다.'));
        await capture('c09-delete-all-empty');
        expect(await api.fetchMyRatings(memberId), isEmpty);
        expect(sentAuthorization, isFalse);
        binding.reportData!['verified'] = 'Actual v6 DELETE 204; one selected DELETE 403 injected, then retried against the server.';
        return;
      }
      await tap(find.text('수정'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(keyed('ratingCommentField')).controller!.text,
        firstComment,
      );
      expect(
        tester.widget<RatingBar>(find.byType(RatingBar)).initialRating,
        4.0,
      );
      await capture('b06-prefilled-edit');
      await selectScore(5);
      const updated = '다시 보고 싶은 영화예요.';
      await tester.enterText(keyed('ratingCommentField'), updated);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 350));
      failNextGet = true;
      await tap(keyed('ratingConfirmButton'));
      await waitFor(find.text('조회 다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ratingCommentField')), findsNothing);
      await capture('b07-live-patch-fixture-get-failed');
      final patchCount = trace
          .where((line) => line.startsWith('PATCH '))
          .length;
      expect(patchCount, 1);
      await tap(find.text('조회 다시 시도'));
      await waitFor(find.text(updated));
      expect(
        trace.where((line) => line.startsWith('PATCH ')).length,
        patchCount,
      );
      expect(find.text('별점 5 / 5'), findsOneWidget);
      await capture('b08-live-get-only-retry');

      await tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await capture('b09-delete-confirm');
      await tap(find.text('취소'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(updated), findsOneWidget);
      expect(trace.where((line) => line.startsWith('DELETE ')), isEmpty);
      await capture('b10-delete-cancelled');
      await tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('삭제'),
        ),
      );
      await waitFor(find.text('아직 등록한 평점이 없습니다.'));
      await capture('b11-live-delete-204-empty');
      expect(
        trace.any(
          (line) => line.startsWith('DELETE ') && line.endsWith(' 204'),
        ),
        isTrue,
      );
      debugPrint('W7 video stop');

      // Reproduce the availability race by replaying the earlier successful checks.
      // The final POST still goes to the real server, using only this test's own account.
      staleAvailability = true;
      AppRouter.router.go('/register');
      await tester.pumpAndSettle();
      await fillSignUp();
      await tap(keyed('registerButton'));
      await waitFor(find.text('이미 사용 중인 이메일입니다.'));
      expect(conflicts, contains('/v6/members'));
      await capture('a03-live-signup-409-stale-check-fixture');
      await tester.enterText(
        keyed('emailField'),
        'changed.$suffix@example.com',
      );
      await tester.pump();
      expect(
        tester.widget<MovieLogButton>(keyed('registerButton')).onPressed,
        isNull,
      );
      expect(find.text('사용 가능한 이메일입니다.'), findsNothing);
      await capture('a04-check-invalidated');
      expect(sentAuthorization, isFalse);
      binding.reportData!['verified'] = requiredMission
          ? 'Actual v6 sign-up and ratings CRUD; sign-up 400s, stale availability and one GET error injected.'
          : 'Actual v6 sign-up and ratings CRUD; stale availability and one GET error injected.';
    },
    skip: !live,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
