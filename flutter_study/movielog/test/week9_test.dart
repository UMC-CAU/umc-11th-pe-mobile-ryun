import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/session/auth_session.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/data/models/favorite_models.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/movie/paged_movie_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/movie/tmdb_movie_detail_screen.dart';
import 'package:movielog/movie/widgets/tmdb_movie_card.dart';
import 'package:movielog/profile/favorites_screen.dart';

class MemoryTokens implements TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? token) async {
    value = token;
  }
}

Future<AuthSession> signedIn() async {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': true,
              'result': options.path.contains('login')
                  ? {'accessToken': 'fixture-token'}
                  : {'email': 'fixture@example.invalid', 'nickname': '테스트'},
            },
          ),
        );
      },
    ),
  );
  final session = AuthSession(dio, MemoryTokens());
  await session.login('fixture@example.invalid', 'fixture');
  return session;
}

TmdbMovieDto movie(int id) => TmdbMovieDto.fromJson({
  'id': id,
  'title': '영화 $id',
  'overview': '',
  'vote_average': 7,
  'poster_path': null,
  'genre_ids': <int>[],
  'release_date': '2026-01-01',
});
TmdbMoviePageDto page(int number, List<int> ids, {int total = 3}) =>
    TmdbMoviePageDto(
      page: number,
      results: ids.map(movie).toList(),
      totalPages: total,
      totalResults: 50,
    );

class MoviesFixture extends TmdbMovieService {
  MoviesFixture() : super(Dio());
  final requests = <(String, int)>[];
  Future<TmdbMoviePageDto> Function(String, int)? respond;
  final failedDetails = <int>{};
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) {
    final query = genreIds?.join(',') ?? '';
    requests.add((query, page));
    return respond?.call(query, page) ??
        Future.value(
          TmdbMoviePageDto(
            page: page,
            results: List.generate(4, (i) => movie(page * 10 + i)),
            totalPages: 2,
            totalResults: 8,
          ),
        );
  }

  @override
  Future<TmdbMoviePageDto> searchMovies({required String query, int page = 1}) {
    requests.add((query, page));
    return respond?.call(query, page) ??
        Future.value(
          TmdbMoviePageDto(
            page: page,
            results: [movie(1)],
            totalPages: 2,
            totalResults: 2,
          ),
        );
  }

  @override
  Future<TmdbMovieDto> fetchMovieDetail(int id) async {
    if (failedDetails.contains(id)) throw StateError('fixture');
    return movie(id);
  }
}

class FavoriteFixture implements FavoriteApi {
  bool favorite = false;
  bool timeout = false;
  DioException? writeError;
  int writes = 0;
  int checks = 0;
  Completer<List<FavoriteResponseDto>>? pending;
  @override
  Future<FavoriteCheckDto> check(int id) async {
    checks++;
    return FavoriteCheckDto(id, favorite);
  }

  @override
  Future<FavoriteResponseDto> add(int id) async {
    writes++;
    if (writeError case final error?) throw error;
    favorite = true;
    if (timeout) {
      throw DioException(
        requestOptions: RequestOptions(path: '/v8/favorites'),
        type: DioExceptionType.receiveTimeout,
      );
    }
    return FavoriteResponseDto(
      favoriteId: id,
      movieId: id,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> remove(int id) async {
    writes++;
    if (writeError case final error?) throw error;
    favorite = false;
  }

  @override
  Future<List<FavoriteResponseDto>> fetchFavorites() =>
      pending?.future ??
      Future.value(
        [1, 2]
            .map(
              (id) => FavoriteResponseDto(
                favoriteId: id,
                movieId: id,
                createdAt: DateTime(2026),
              ),
            )
            .toList(),
      );
  @override
  Future<MovieRecordResponse> saveRecord(CreateMovieRecordRequest request) =>
      throw UnimplementedError();
}

void main() {
  test('v8 service accepts 200/null delete, status without movieId and record favorite null', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final Object? result = request.method == 'DELETE'
              ? null
              : request.path == '/v8/movie-records'
              ? {
                  'rating': {
                    'ratingId': 1,
                    'movieId': 550,
                    'score': 4,
                    'comment': null,
                    'createdAt': '2026-11-16T00:00:00Z',
                  },
                  'favorite': null,
                }
              : {'isFavorite': true};
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: request.method == 'POST' ? 201 : 200,
              data: {
                'isSuccess': true,
                'code': 'COMMON200',
                'message': 'ok',
                'result': result,
              },
            ),
          );
        },
      ),
    );
    final api = FavoriteApiService(dio);
    await api.remove(550);
    final status = await api.check(550);
    expect(status.movieId, 550);
    expect(status.isFavorite, true);
    final record = await api.saveRecord(
      CreateMovieRecordRequest(movieId: 550, score: 4, addToFavorites: false),
    );
    expect(record.rating.movieId, 550);
    expect(record.favorite, isNull);
    expect(requests.last.data, {
      'movieId': 550,
      'score': 4,
      'addToFavorites': false,
    });
    expect(requests.first.path, '/v8/favorites/550');
  });
  test('only the three protected 401 codes mean session expiry', () {
    for (final code in [
      'AUTH401_2',
      'AUTH401_3',
      'AUTH401_4',
      'AUTH401_1',
      'MEMBER404_1',
      'FAVORITE404_1',
    ]) {
      for (final status in [401, 403, 404]) {
        final request = RequestOptions(path: '/v8/favorites');
        final error = DioException(
          requestOptions: request,
          response: Response(
            requestOptions: request,
            statusCode: status,
            data: {'code': code},
          ),
        );
        expect(
          isSessionExpired(error),
          status == 401 &&
              {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(code),
        );
      }
    }
  });
  testWidgets(
    'favorites root route opens detail without duplicate shell page keys and refreshes on return',
    (tester) async {
      final session = (await tester.runAsync(signedIn))!;
      final api = FavoriteFixture();
      AppRouter.router.go('/my/favorites');
      await tester.pumpWidget(
        MovieLogApp(
          authSession: session,
          movieService: MoviesFixture(),
          favoriteApi: api,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesScreen), findsOneWidget);
      await tester.tap(find.byType(TmdbMovieCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(TmdbMovieDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'pagination deduplicates, keeps old cards, retries exactly the failed page',
    () async {
      final api = MoviesFixture();
      var fail = true;
      api.respond = (query, number) async {
        if (number == 2 && fail) throw StateError('offline');
        return page(number, number == 1 ? [1, 2] : [2, 3], total: 2);
      };
      final vm = PagedMoviesViewModel(api);
      await vm.loadInitial();
      await vm.loadNextPage();
      expect(vm.movies.map((m) => m.id), [1, 2]);
      expect(vm.nextPage, 2);
      expect(vm.loadMoreError, isNotNull);
      fail = false;
      await Future.wait([vm.loadNextPage(), vm.loadNextPage()]);
      expect(api.requests.map((r) => r.$2), [1, 2, 2]);
      expect(vm.movies.map((m) => m.id), [1, 2, 3]);
      expect(vm.hasMore, false);
      vm.dispose();
    },
  );
  test(
    'old query response and finally cannot overwrite a newer request',
    () async {
      final api = MoviesFixture();
      final old = Completer<TmdbMoviePageDto>();
      final newer = Completer<TmdbMoviePageDto>();
      api.respond = (query, number) =>
          query == 'old' ? old.future : newer.future;
      final vm = PagedMoviesViewModel(api, searchMode: true);
      final a = vm.loadInitial(query: 'old');
      final b = vm.loadInitial(query: 'new');
      old.complete(page(1, [1]));
      await a;
      expect(vm.phase, LoadPhase.loading);
      expect(vm.movies, isEmpty);
      newer.complete(page(1, [2]));
      await b;
      expect(vm.movies.single.id, 2);
      await vm.loadInitial(query: '  ');
      expect(vm.movies, isEmpty);
      expect(api.requests.length, 2);
      vm.dispose();
    },
  );
  test(
    'genre reset supersedes a pending next page and resets loading/error',
    () async {
      final api = MoviesFixture();
      final pending = Completer<TmdbMoviePageDto>();
      api.respond = (query, number) => number == 2
          ? pending.future
          : Future.value(page(1, [query == '9' ? 9 : 1]));
      final vm = PagedMoviesViewModel(api);
      await vm.loadInitial();
      final old = vm.loadNextPage();
      await vm.loadInitial(genres: [9]);
      pending.completeError(StateError('old failure'));
      await old;
      expect(vm.movies.single.id, 9);
      expect(vm.loadMoreError, isNull);
      expect(vm.isLoadingMore, false);
      vm.dispose();
    },
  );
  test('dispose during a request suppresses notifications', () async {
    final api = MoviesFixture();
    final pending = Completer<TmdbMoviePageDto>();
    api.respond = (_, _) => pending.future;
    final vm = PagedMoviesViewModel(api);
    final request = vm.loadInitial();
    vm.dispose();
    pending.complete(page(1, [1]));
    await request;
    expect(vm.movies, isEmpty);
  });
  test('bounded movie joins preserve order and never exceed five concurrent requests', () async {
    var active = 0;
    var maximum = 0;
    final values = await mapBounded(List.generate(100, (i) => i), (
      int value,
    ) async {
      active++;
      if (active > maximum) maximum = active;
      await Future<void>.delayed(Duration.zero);
      active--;
      return value;
    });
    expect(maximum, 5);
    expect(values, List.generate(100, (i) => i));
  });
  test('one movie failure leaves other favorites and card retry restores only that card', () async {
    final session = await signedIn();
    final api = FavoriteFixture();
    final movies = MoviesFixture()..failedDetails.add(2);
    final vm = FavoritesViewModel(api, movies, session);
    await vm.refresh();
    expect(vm.phase, LoadPhase.success);
    expect(vm.items[1].movie, isNull);
    movies.failedDetails.clear();
    await vm.retryMovie(2);
    expect(vm.items[1].movie?.id, 2);
    vm.dispose();
    session.dispose();
  });
  test('account switch rejects a late favorites list', () async {
    final session = await signedIn();
    final api = FavoriteFixture()
      ..pending = Completer<List<FavoriteResponseDto>>();
    final vm = FavoritesViewModel(api, MoviesFixture(), session);
    final request = vm.refresh();
    await session.logout();
    await session.login('new@example.invalid', 'fixture');
    api.pending!.complete([
      FavoriteResponseDto(favoriteId: 1, movieId: 1, createdAt: DateTime(2026)),
    ]);
    await request;
    expect(vm.items, isEmpty);
    vm.dispose();
    session.dispose();
  });
  test('a timed out write is followed by GET confirmation, never an automatic POST retry', () async {
    final session = await signedIn();
    final api = FavoriteFixture()..timeout = true;
    final vm = FavoriteDetailViewModel(api, session, 1);
    await vm.load();
    await vm.toggle();
    expect(vm.isFavorite, false);
    expect(vm.known, false);
    await vm.toggle();
    expect(api.writes, 1);
    expect(api.checks, 2);
    expect(vm.isFavorite, true);
    vm.dispose();
    session.dispose();
  });
  test(
    'favorite conflicts resync with GET without repeating a write',
    () async {
      for (final (initial, code, status, serverState) in [
        (false, 'FAVORITE409_1', 409, true),
        (true, 'FAVORITE404_1', 404, false),
      ]) {
        final session = await signedIn();
        final api = FavoriteFixture()..favorite = initial;
        final vm = FavoriteDetailViewModel(api, session, 550);
        await vm.load();
        final request = RequestOptions(path: '/v8/favorites/550');
        api
          ..favorite = serverState
          ..writeError = DioException(
            requestOptions: request,
            response: Response(
              requestOptions: request,
              statusCode: status,
              data: {'code': code},
            ),
            type: DioExceptionType.badResponse,
          );
        await vm.toggle();
        expect(vm.isFavorite, serverState);
        expect(vm.known, isTrue);
        expect(api.writes, 1);
        expect(api.checks, 2);
        expect(session.authenticated, isTrue);
        vm.dispose();
        session.dispose();
      }
    },
  );
  test(
    'old-session expiry cannot log out a new session; current expiry runs once',
    () async {
      final session = await signedIn();
      final old = session.generation;
      await session.logout();
      await session.login('new@example.invalid', 'fixture');
      await session.expire(old);
      expect(session.authenticated, true);
      final current = session.generation;
      await Future.wait([session.expire(current), session.expire(current)]);
      expect(session.authenticated, false);
      expect(session.generation, current + 1);
      session.dispose();
    },
  );
  test(
    'JWT host/path boundary excludes TMDB, public paths, and lookalike hosts',
    () async {
      final session = await signedIn();
      final interceptor = AuthInterceptor(session);
      expect(
        interceptor.protected(
          RequestOptions(
            baseUrl: 'https://workbook.devnoco.com',
            path: '/v8/favorites/1',
          ),
        ),
        true,
      );
      for (final url in [
        'https://api.themoviedb.org/3/movie/1',
        'https://workbook.devnoco.com.evil.invalid/v8/favorites',
        'http://workbook.devnoco.com/v8/favorites',
        'https://workbook.devnoco.com/v8/members/1/ratings',
      ]) {
        expect(interceptor.protected(RequestOptions(path: url)), false);
      }
      session.dispose();
    },
  );
  testWidgets(
    'debounce waits 500ms, submit cancels timer, empty input never requests',
    (tester) async {
      final api = MoviesFixture();
      final vm = PagedMoviesViewModel(api, searchMode: true);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<TmdbMovieService>.value(value: api),
            ChangeNotifierProvider<PagedMoviesViewModel>.value(value: vm),
          ],
          child: const MaterialApp(home: PagedMovieListScreen(search: true)),
        ),
      );
      final field = find.byKey(const Key('movieSearchField'));
      await tester.enterText(field, '어');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(field, '어벤져스');
      await tester.pump(const Duration(milliseconds: 499));
      expect(api.requests, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(api.requests, [('어벤져스', 1)]);
      await tester.enterText(field, '배트맨');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(api.requests.length, 2);
      await tester.enterText(field, '  ');
      await tester.pump(const Duration(seconds: 1));
      expect(api.requests.length, 2);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
}
