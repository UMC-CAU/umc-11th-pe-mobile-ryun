import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/session/auth_session.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie/paged_movie_list_screen.dart';
import 'package:movielog/movie/tmdb_movie_detail_screen.dart';
import 'package:movielog/movie/widgets/tmdb_movie_card.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Week 9 missing video evidence, host-synchronized recording',
    (tester) async {
      await dotenv.load(fileName: '.env');
      final publicClient = createMovieLogClient();
      final storage = SecureTokenStorage(
        key: 'movielog.week9.additional-video',
      );
      final session = AuthSession(publicClient, storage)..initialized = true;
      final authClient = createMovieLogClient()
        ..interceptors.add(AuthInterceptor(session));
      final tmdbClient = createTmdbClient();
      final trace = <String>[];
      final screens = <String, String>{};
      final assertions = <String>[];
      final discoverPages = <int>[];
      final movies = TmdbMovieService(tmdbClient);
      final api = FavoriteApiService(authClient);
      final signup = SignUpService(publicClient, version: 'v8');
      var failThirdPage = true;
      binding.reportData = {
        'renderedScreens': screens,
        'apiTrace': trace,
        'assertions': assertions,
        'mode': 'required-additional-videos',
        'discoverPages': discoverPages,
        'recording': 'Host starts screenrecord and acknowledges before any demonstrated action.',
      };
      addTearDown(() async {
        await storage.write(null);
        publicClient.close(force: true);
        authClient.close(force: true);
        tmdbClient.close(force: true);
      });
      authClient.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            if (request.path.startsWith('/v8/favorites') &&
                request.method != 'GET') {
              await Future<void>.delayed(const Duration(milliseconds: 800));
            }
            handler.next(request);
          },
          onResponse: (response, handler) {
            trace.add(
              'live: ${response.requestOptions.method} ${response.requestOptions.path} -> ${response.statusCode}',
            );
            handler.next(response);
          },
        ),
      );
      tmdbClient.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            if (request.path == '/discover/movie') {
              final page = request.queryParameters['page'] as int;
              discoverPages.add(page);
              if (page > 1) {
                await Future<void>.delayed(const Duration(milliseconds: 1000));
              }
              if (page == 3 && failThirdPage) {
                failThirdPage = false;
                trace.add(
                  'fixture: GET /discover/movie page=3 -> 503 (before transport)',
                );
                handler.reject(
                  DioException(
                    requestOptions: request,
                    type: DioExceptionType.badResponse,
                    response: Response(
                      requestOptions: request,
                      statusCode: 503,
                      data: {
                        'isSuccess': false,
                        'code': 'FIXTURE503',
                        'message': '촬영용 조회 실패',
                        'result': null,
                      },
                    ),
                  ),
                );
                return;
              }
            }
            handler.next(request);
          },
          onResponse: (response, handler) {
            final request = response.requestOptions;
            trace.add(
              'live: GET ${request.path}${request.queryParameters['page'] == null ? '' : ' page=${request.queryParameters['page']}'} -> ${response.statusCode}',
            );
            handler.next(response);
          },
        ),
      );
      final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      final password = 'W9v!${Random.secure().nextInt(1 << 30)}X';
      final email = 'w9video$nonce@example.invalid';
      await signup.signUp(
        CreateMemberRequest(
          email: email,
          password: password,
          nickname: 'w9v${nonce.substring(nonce.length - 6)}',
        ),
      );
      await session.login(email, password);
      final key = GlobalKey();
      AppRouter.router.go('/movies');
      runApp(
        RepaintBoundary(
          key: key,
          child: MovieLogApp(
            authSession: session,
            movieService: movies,
            favoriteApi: api,
            signUpService: signup,
          ),
        ),
      );

      Future<void> tick([int milliseconds = 80]) async {
        await tester.pump(Duration(milliseconds: milliseconds));
        await tester.runAsync(
          () => Future<void>.delayed(Duration(milliseconds: milliseconds)),
        );
      }

      Future<void> until(bool Function() ready, String name) async {
        for (var i = 0; i < 400; i++) {
          await tick();
          if (ready()) return;
        }
        throw StateError('Timed out: $name');
      }

      Future<void> hold(int seconds) async {
        for (var i = 0; i < seconds * 10; i++) {
          await tick(100);
        }
      }

      Future<void> hostGate(String stage, bool start) async {
        final suffix = start ? 'started' : 'stopped';
        final file = File('${Directory.systemTemp.path}/week9-$stage-$suffix');
        if (await file.exists()) await file.delete();
        debugPrint(
          'W9_VIDEO_${start ? 'READY' : 'DONE'}:$stage:${Directory.systemTemp.path}',
        );
        await until(() => file.existsSync(), 'host recording $suffix');
        if (start) await hold(2);
      }

      Future<void> capture(String name) async {
        await tester.pump();
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
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        screens[name] = base64Encode(bytes!.buffer.asUint8List());
        image.dispose();
      }

      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tick();
        await tester.tap(target);
        await tick();
      }

      PagedMoviesViewModel list() => tester
          .element(find.byType(PagedMovieListScreen))
          .read<PagedMoviesViewModel>();
      FavoriteDetailViewModel detail() => tester
          .element(find.byType(TmdbMovieDetailScreen))
          .read<FavoriteDetailViewModel>();
      await until(
        () => find.byType(TmdbMovieCard).evaluate().isNotEmpty,
        'initial movies',
      );
      await tap(find.byType(TmdbMovieCard).first);
      await until(
        () =>
            find.byType(TmdbMovieDetailScreen).evaluate().isNotEmpty &&
            detail().known &&
            !detail().busy,
        'initial favorite status',
      );
      expect(detail().isFavorite, false);
      await hostGate('bookmark', true);
      await capture('v01-before-bookmark-registration');
      await tap(find.byKey(const Key('favoriteButton')));
      await until(
        () =>
            detail().isFavorite &&
            !detail().busy &&
            find.text('즐겨찾기에 추가했습니다.').evaluate().isNotEmpty,
        'favorite POST and snackbar',
      );
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      await capture('v02-bookmark-added-snackbar');
      await hold(3);
      ScaffoldMessenger.of(tester.element(find.byType(TmdbMovieDetailScreen)))
          .clearSnackBars();
      await tick(300);
      await tap(find.byKey(const Key('favoriteButton')));
      await until(
        () =>
            !detail().isFavorite &&
            !detail().busy &&
            find.text('즐겨찾기를 해제했습니다.').evaluate().isNotEmpty,
        'favorite DELETE and snackbar',
      );
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      await capture('v03-bookmark-removed-snackbar');
      await hold(3);
      await hostGate('bookmark', false);
      assertions.add(
        'Bookmark video: initial unregistered state -> actual tap -> POST 201 -> filled icon + Snackbar -> DELETE 200 -> outline icon + Snackbar.',
      );

      AppRouter.router.pop();
      await hold(1);
      final model = list();
      final firstCount = model.movies.length;
      await tester.scrollUntilVisible(
        find.text('더 보기'),
        600,
        scrollable: find.byType(Scrollable).last,
      );
      await tick(300);
      await hostGate('more-button', true);
      await capture('v04-required-more-button');
      await tap(find.text('더 보기'));
      await until(
        () => model.nextPage == 3 && !model.isLoadingMore,
        'page 2 actual success',
      );
      expect(model.movies.length, greaterThan(firstCount));
      await hold(2);
      await tester.scrollUntilVisible(
        find.text('더 보기'),
        600,
        scrollable: find.byType(Scrollable).last,
      );
      await hold(1);
      await capture('v05-page-two-appended');
      final secondCount = model.movies.length;
      await tap(find.text('더 보기'));
      await until(
        () => model.loadMoreError != null && !model.isLoadingMore,
        'page 3 fixture failure',
      );
      expect(model.nextPage, 3);
      expect(model.movies.length, secondCount);
      await capture('v06-page-three-failed-cards-retained');
      await hold(3);
      await tap(find.text('다시 시도'));
      await until(
        () => model.nextPage == 4 && !model.isLoadingMore,
        'same page 3 actual retry',
      );
      expect(model.movies.length, greaterThan(secondCount));
      expect(discoverPages, [1, 2, 3, 3]);
      expect(
        model.movies.map((movie) => movie.id).toSet().length,
        model.movies.length,
      );
      await hold(2);
      await tester.scrollUntilVisible(
        find.text('더 보기'),
        600,
        scrollable: find.byType(Scrollable).last,
      );
      await capture('v07-same-page-three-retry-success');
      await hold(3);
      await hostGate('more-button', false);
      assertions.add(
        'Required video: More button -> live page 2 append -> fixture page 3 failure preserves cards -> retry live page 3, request sequence [1,2,3,3], no duplicate movie IDs.',
      );
      binding.reportData!['movieCounts'] = [
        firstCount,
        secondCount,
        model.movies.length,
      ];
      await session.logout();
      await tick();
    },
    skip: !const bool.fromEnvironment('WEEK9_CAPTURE_LIVE'),
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
