import 'dart:convert';
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
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/session/auth_session.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie/paged_movie_list_screen.dart';
import 'package:movielog/movie/tmdb_movie_detail_screen.dart';
import 'package:movielog/movie/widgets/tmdb_movie_card.dart';
import 'package:movielog/profile/favorites_screen.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const live = bool.fromEnvironment('WEEK9_CAPTURE_LIVE');
  const challenge = bool.fromEnvironment('WEEK9_CHALLENGE', defaultValue: true);
  const recordFlows = bool.fromEnvironment('WEEK9_RECORD_FLOWS');
  testWidgets(
    'Week 9 live Guided, Required and Challenge evidence',
    (tester) async {
      await dotenv.load(fileName: '.env');
      final publicClient = createMovieLogClient();
      final storage = SecureTokenStorage(key: 'movielog.week9.capture');
      final session = AuthSession(publicClient, storage)..initialized = true;
      final authClient = createMovieLogClient()
        ..interceptors.add(AuthInterceptor(session));
      final tmdbClient = createTmdbClient();
      addTearDown(() async {
        try {
          await storage.write(null);
        } on Object {
          /* Report is independent of storage cleanup. */
        }
        publicClient.close(force: true);
        authClient.close(force: true);
        tmdbClient.close(force: true);
      });
      final trace = <String>[];
      final screens = <String, String>{};
      final assertions = <String>[];
      binding.reportData = {
        'renderedScreens': screens,
        'apiTrace': trace,
        'assertions': assertions,
        'mode': challenge ? 'challenge' : 'required',
        'captureType': 'Android Flutter render, real API unless explicitly labeled fixture',
      };
      var failFavorites = false;
      int? failMovie;
      var failPage = false;
      var failRecord = false;
      var failSearch = false;
      DioException failure(RequestOptions request, String label) =>
          DioException(
            requestOptions: request,
            response: Response(
              requestOptions: request,
              statusCode: 503,
              data: {
                'isSuccess': false,
                'code': 'FIXTURE503',
                'message': label,
                'result': null,
              },
            ),
            type: DioExceptionType.badResponse,
          );
      void addTrace(Dio client, {bool tmdb = false}) {
        client.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              if (failFavorites &&
                  request.path == '/v8/favorites' &&
                  request.method == 'GET') {
                failFavorites = false;
                trace.add('fixture: favorites GET 503');
                handler.reject(failure(request, '즐겨찾기 조회 실패 테스트'));
                return;
              }
              if (tmdb && request.path == '/movie/$failMovie') {
                failMovie = null;
                trace.add('fixture: one TMDB detail GET 503');
                handler.reject(failure(request, '영화 정보 조회 실패 테스트'));
                return;
              }
              if (tmdb &&
                  failPage &&
                  request.path == '/discover/movie' &&
                  request.queryParameters['page'] == 2) {
                failPage = false;
                trace.add('fixture: discover page=2 GET 503');
                handler.reject(failure(request, '다음 페이지 조회 실패 테스트'));
                return;
              }
              if (tmdb && failSearch && request.path == '/search/movie') {
                failSearch = false;
                trace.add('fixture: search GET 503');
                handler.reject(failure(request, '검색 실패 테스트'));
                return;
              }
              if (failRecord && request.path == '/v8/movie-records') {
                failRecord = false;
                trace.add('fixture: movie-records POST network failure');
                handler.reject(
                  DioException(
                    requestOptions: request,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              handler.next(request);
            },
            onResponse: (response, handler) {
              final r = response.requestOptions;
              final page = r.queryParameters['page'];
              trace.add(
                'live: ${r.method} ${r.path}${page == null ? '' : ' page=$page'} -> ${response.statusCode}',
              );
              handler.next(response);
            },
            onError: (error, handler) {
              if (error.response?.statusCode != 503 &&
                  error.type != DioExceptionType.connectionError) {
                trace.add(
                  'live: ${error.requestOptions.method} ${error.requestOptions.path} -> ${error.response?.statusCode ?? error.type.name}',
                );
              }
              handler.next(error);
            },
          ),
        );
      }

      addTrace(publicClient);
      addTrace(authClient);
      addTrace(tmdbClient, tmdb: true);
      final movies = TmdbMovieService(tmdbClient);
      final api = FavoriteApiService(authClient);
      final ratings = RatingApiService(
        authClient,
        authenticated: true,
        sessionVersion: () => session.generation,
      );
      final signup = SignUpService(publicClient, version: 'v8');
      final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      final password = 'W9a!${Random.secure().nextInt(1 << 30)}X';
      final emailA = 'w9a$nonce@example.invalid';
      final emailB = 'w9b$nonce@example.invalid';
      Future<void> account(String email, String suffix) async {
        await signup.signUp(
          CreateMemberRequest(
            email: email,
            password: password,
            nickname: 'w9$suffix${nonce.substring(nonce.length - 6)}',
          ),
        );
      }

      await account(emailA, 'a');
      await session.login(emailA, password);
      expect(await storage.read(), isNotNull);
      final restored = AuthSession(publicClient, storage);
      await restored.restore();
      expect(restored.authenticated, true);
      restored.dispose();
      assertions.add(
        'real Android secure storage write/read and GET me restoration passed',
      );
      final key = GlobalKey();
      AppRouter.router.go('/movies');
      void runMovieApp() => runApp(
        RepaintBoundary(
          key: key,
          child: MovieLogApp(
            movieService: movies,
            authSession: session,
            favoriteApi: api,
            ratingApiService: ratings,
            signUpService: signup,
          ),
        ),
      );
      Future<void> until(bool Function() ready, String label) async {
        for (var i = 0; i < 250; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          if (ready()) return;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
        }
        throw StateError('Timed out: $label');
      }

      Future<void> settle() async {
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }

      Future<void> recordingGate(String stage, bool start) async {
        if (!recordFlows) return;
        final suffix = start ? 'started' : 'stopped';
        final file = File('${Directory.systemTemp.path}/week9-$stage-$suffix');
        if (await file.exists()) await file.delete();
        debugPrint(
          'W9_VIDEO_${start ? 'READY' : 'DONE'}:$stage:${Directory.systemTemp.path}',
        );
        await until(() => file.existsSync(), 'host recording $suffix');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        await tester.pump();
      }

      Future<void> capture(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        for (var i = 0; i < 6; i++) {
          await settle();
          if (tester.view.viewInsets.bottom == 0) break;
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
        final image = await boundary.toImage(
          pixelRatio: tester.view.devicePixelRatio,
        );
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        screens[name] = base64Encode(data!.buffer.asUint8List());
        image.dispose();
        debugPrint('W9 captured: $name');
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pump();
        await tester.tap(finder);
        await settle();
      }

      PagedMoviesViewModel listModel() => tester
          .element(find.byType(PagedMovieListScreen).last)
          .read<PagedMoviesViewModel>();
      FavoriteDetailViewModel detailModel() => tester
          .element(find.byType(TmdbMovieDetailScreen))
          .read<FavoriteDetailViewModel>();
      FavoritesViewModel favoritesModel() => tester
          .element(find.byType(FavoritesScreen))
          .read<FavoritesViewModel>();
      Future<void> studyCapture(
        String name,
        String title,
        List<String> lines,
      ) async {
        runApp(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: const Color(0xFFFAF9F5),
                appBar: AppBar(title: Text(title)),
                body: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      '9주차 학습 기록 · 문서 미리보기',
                      style: TextStyle(color: Color(0xFF4F378A)),
                    ),
                    const SizedBox(height: 16),
                    for (final line in lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          line,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await settle();
        await capture(name);
      }

      if (challenge) {
        await studyCapture('s01-concepts', '개념 먼저 잡기', [
          'Map: movieId를 key로 TMDB 영화 정보를 찾는다.',
          'Future.wait: 여러 비동기 결과를 입력 순서대로 모은다. 영화 상세 요청은 동시에 최대 5개로 제한한다.',
          'record: 세션 번호와 검색 조건 등 여러 값을 이름과 함께 묶는다.',
          'interface: 실제 서버와 테스트 서비스가 지키는 공통 메서드 계약이다.',
          'mixin: dispose 뒤 알림 방지 같은 공통 동작을 공유한다.',
          'ValueKey: 계정과 세션이 바뀌면 이전 ViewModel을 폐기한다.',
          'generation: 이전 요청의 응답·오류·finally가 새 상태를 덮어쓰지 못하게 한다.',
        ]);
        await studyCapture('s02-requirements', '요구사항과 작업 순서', [
          '선행 작업: v6 학습용 회원 ID → v8 JWT 로그인·보안 저장소·세션 보호.',
          'Guided A/B: 상세 북마크 API → 내 즐겨찾기 목록과 상세 복귀 갱신.',
          'Required: 더 보기·같은 page 재시도·독립 검색 화면·계정 전환 검증.',
          'Challenge: 500ms debounce → 무한 스크롤 → 평점과 즐겨찾기 통합 저장.',
          'API 차이: 즐겨찾기 해제와 v8 평점 삭제는 모두 200 / result: null.',
          '증빙: 실제 서버 성공과 fixture로 주입한 실패를 구분하고 토큰·개인 정보를 숨긴다.',
        ]);
      }
      runMovieApp();
      await settle();
      await until(
        () => find.byType(TmdbMovieCard).evaluate().isNotEmpty,
        'first movies',
      );
      final movie = listModel().movies.first;
      final second = listModel().movies[1];
      await capture('g01-first-page');
      await tap(find.byType(TmdbMovieCard).first);
      await until(
        () => detailModel().known && !detailModel().busy,
        'favorite GET',
      );
      await capture('g02-live-favorite-off');
      await tap(find.byKey(const Key('favoriteButton')));
      await until(
        () => detailModel().isFavorite && !detailModel().busy,
        'favorite POST',
      );
      await capture('g03-live-favorite-added');
      await recordingGate('favorites-return', true);
      AppRouter.router.go('/my');
      await settle();
      await capture('g04-profile-favorites-entry');
      await tap(find.text('내 즐겨찾기'));
      await until(
        () => favoritesModel().phase == LoadPhase.success,
        'favorites GET and join',
      );
      await capture('g05-live-favorites-list');
      await tap(find.byType(TmdbMovieCard).first);
      await until(() => detailModel().known, 'favorite status on detail');
      await tap(find.byKey(const Key('favoriteButton')));
      await until(
        () => !detailModel().isFavorite && !detailModel().busy,
        'favorite DELETE 200',
      );
      AppRouter.router.pop();
      await settle();
      await until(
        () => favoritesModel().phase == LoadPhase.empty,
        'return refresh empty',
      );
      await capture('g06-live-return-empty');
      await recordingGate('favorites-return', false);
      assertions.add(
        'favorite POST/GET/DELETE and detail-return refresh passed',
      );
      // Actual favorites with a deliberately failed TMDB detail request.
      await api.add(movie.id);
      await api.add(second.id);
      AppRouter.router.go('/my');
      await settle();
      failMovie = second.id;
      await tap(find.text('내 즐겨찾기'));
      await until(
        () => favoritesModel().phase == LoadPhase.success,
        'partial join',
      );
      await capture('r01-fixture-one-movie-failed');
      await tap(find.text('정보 다시 불러오기'));
      await until(
        () => favoritesModel().items.every((item) => item.movie != null),
        'one-card retry',
      );
      await capture('r02-live-one-card-recovered');
      failFavorites = true;
      await favoritesModel().refresh();
      await settle();
      await capture('r03-fixture-favorites-error');
      await tap(find.text('다시 시도'));
      await until(
        () => favoritesModel().phase == LoadPhase.success,
        'favorites retry',
      );
      await capture('r04-live-favorites-recovered');
      AppRouter.router.go('/movies');
      await settle();
      final list = listModel();
      final count = list.movies.length;
      failPage = true;
      if (!challenge) {
        await tester.scrollUntilVisible(
          find.text('더 보기'),
          600,
          scrollable: find.byType(Scrollable).last,
        );
        await capture('r00-more-button');
        await tap(find.text('더 보기'));
      } else {
        await tester.drag(
          find.byType(CustomScrollView).last,
          const Offset(0, -9000),
        );
        await settle();
      }
      await until(() => list.loadMoreError != null, 'page 2 fixture failure');
      expect(list.nextPage, 2);
      expect(list.movies.length, count);
      await tester.drag(
        find.byType(CustomScrollView).last,
        const Offset(0, -9000),
      );
      await settle();
      await capture(
        challenge ? 'c01-infinite-scroll-error' : 'r05-page-two-error',
      );
      await tap(find.text('다시 시도'));
      await until(
        () => list.nextPage == 3 && !list.isLoadingMore,
        'same page 2 retry',
      );
      expect(list.movies.length, greaterThan(count));
      await capture(
        challenge ? 'c02-infinite-scroll-recovered' : 'r06-page-two-recovered',
      );
      assertions.add(
        'page 2 failure preserved cards; retry requested page 2 and deduplicated append',
      );
      await recordingGate('search-flow', true);
      await tap(find.byTooltip('검색'));
      final search = find.byKey(const Key('movieSearchField'));
      await tester.enterText(search, '어벤져스');
      if (!challenge) {
        await tester.testTextInput.receiveAction(TextInputAction.search);
      } else {
        await tester.pump(const Duration(milliseconds: 550));
      }
      await until(
        () => listModel().phase == LoadPhase.success,
        'search results',
      );
      await capture(
        challenge
            ? 'c03-debounce-search-results'
            : 'r07-submitted-search-results',
      );
      await tap(find.byType(TmdbMovieCard).first);
      await until(() => detailModel().known, 'search to detail');
      await capture('r08-search-to-detail');
      AppRouter.router.pop();
      await settle();
      await tester.enterText(search, 'w9-no-such-film-$nonce');
      await tester.pump();
      tester.widget<TextField>(search).onSubmitted!('w9-no-such-film-$nonce');
      await until(() => listModel().phase == LoadPhase.empty, 'empty search');
      await capture('r09-live-search-empty');
      failSearch = true;
      await tester.enterText(search, '배트맨');
      await tester.pump();
      tester.widget<TextField>(search).onSubmitted!('배트맨');
      await until(
        () => listModel().phase == LoadPhase.error,
        'fixture search error',
      );
      await capture('r10-fixture-search-error');
      await recordingGate('search-flow', false);
      if (challenge) {
        AppRouter.router.go('/movies/${movie.id}', extra: movie);
        await settle();
        // Clear only data created in this test account; the dialog must offer the checkbox.
        await api.remove(movie.id);
        await detailModel().load();
        await settle();
        await tap(find.text('평점 남기기'));
        await capture('c04-rating-checkbox-no-score');
        final bar = tester.widget<RatingBar>(find.byType(RatingBar));
        bar.onRatingUpdate(4);
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('ratingCommentField')),
          '9주차 통합 저장 실습',
        );
        await tap(find.text('즐겨찾기에도 추가'));
        failRecord = true;
        await tap(find.byKey(const Key('ratingConfirmButton')));
        await until(
          () => find.text('요청에 실패했습니다. 잠시 후 다시 시도해 주세요.').evaluate().isNotEmpty,
          'record network failure',
        );
        await capture('c05-fixture-record-error-input-retained');
        await tap(find.byKey(const Key('ratingConfirmButton')));
        await until(
          () => find.text('평점을 저장했습니다.').evaluate().isNotEmpty,
          'record POST 201',
        );
        await until(
          () => detailModel().known && detailModel().isFavorite,
          'record bookmark sync',
        );
        await capture('c06-live-record-saved');
        assertions.add(
          'movie-records 201 transaction, checkbox, input retention, and bookmark resync passed',
        );
      }
      // Account A has favorites; account B must start with none.
      await account(emailB, 'b');
      await session.logout();
      await settle();
      AppRouter.router.go('/login');
      await settle();
      await capture('r11-logged-out');
      await session.login(emailB, password);
      await settle();
      AppRouter.router.go('/my/favorites');
      await settle();
      await until(
        () => favoritesModel().phase == LoadPhase.empty,
        'account B empty',
      );
      await capture('r12-live-account-b-empty');
      assertions.add(
        'account switch A to B: previous favorites did not appear',
      );
      await session.logout();
      await studyCapture('s03-sanitized-api-log', '민감값 제외 API 검증 기록', [
        'Android 에뮬레이터 · 실제 API 응답. 토큰·이메일·비밀번호·요청 body는 표시하지 않음.',
        ...trace.where((line) => line.contains('/v8/')).take(10),
        '전체 호출 순서와 검증 결과: capture-result.json',
      ]);
      publicClient.close(force: true);
      authClient.close(force: true);
      tmdbClient.close(force: true);
    },
    skip: !live,
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
