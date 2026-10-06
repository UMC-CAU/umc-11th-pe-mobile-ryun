import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/data/sort_preference.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/models/movie_sort_order.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_list_empty.dart';
import 'package:movielog/movie/widgets/movie_list_error.dart';
import 'package:movielog/movie/widgets/movie_list_loading.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _ControlledMovieService extends FakeMovieService {
  final requests = <Completer<List<Movie>>>[];

  @override
  Future<List<Movie>> fetchMovies() {
    final request = Completer<List<Movie>>();
    requests.add(request);
    return request.future;
  }
}

GoRouter _router(FakeMovieService service) {
  final router = GoRouter(
    initialLocation: '/movies',
    routes: [
      GoRoute(
        path: '/movies',
        builder: (context, state) => MovieListScreen(
          movieService: service,
          selectedGenres: state.uri.queryParametersAll['genre'],
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

List<int> _movieIds(WidgetTester tester) => tester
    .widget<MovieGrid>(find.byType(MovieGrid))
    .movies
    .map((movie) => movie.id)
    .toList();

Future<void> _selectSort(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('movieSortButton')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.widgetWithText(CheckedPopupMenuItem<MovieSortOrder>, label),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Skeleton을 표시하고 짧은 Success 목록도 당겨서 새로고침한다', (tester) async {
    final service = _ControlledMovieService();
    final router = _router(service);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(MovieCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    service.requests.single.complete([movies.first]);
    await tester.pumpAndSettle();
    expect(_movieIds(tester), [1]);
    await tester.drag(find.byType(GridView), const Offset(0, 350));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.requests, hasLength(2));
    expect(find.byType(MovieListLoading), findsOneWidget);

    service.requests.last.complete([movies.last]);
    await tester.pumpAndSettle();
    expect(_movieIds(tester), [6]);
    expect(tester.takeException(), isNull);
  });

  for (final isError in [false, true]) {
    testWidgets('${isError ? 'Error' : 'Empty'} 화면에서도 당기면 Success로 복구한다', (
      tester,
    ) async {
      final service = _ControlledMovieService();
      final router = _router(service);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      if (isError) {
        service.requests.single.completeError(StateError('internal_failure'));
      } else {
        service.requests.single.complete([]);
      }
      await tester.pumpAndSettle();
      expect(
        find.byType(isError ? MovieListError : MovieListEmpty),
        findsOneWidget,
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.requests, hasLength(2));
      service.requests.last.complete(movies);
      await tester.pumpAndSettle();
      expect(_movieIds(tester), [1, 2, 3, 4, 5, 6]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('새로고침 중 중복 요청을 막고 실패는 Error로 처리한다', (tester) async {
    final service = _ControlledMovieService();
    final router = _router(service);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    service.requests.single.complete(movies);
    await tester.pumpAndSettle();

    final onRefresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh;
    final first = onRefresh();
    final second = onRefresh();
    await tester.pump();
    expect(service.requests, hasLength(2));
    service.requests.last.completeError(StateError('internal_refresh_error'));
    await tester.pumpAndSettle();
    await Future.wait([first, second]);
    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.textContaining('internal_refresh'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('5초 Timeout 뒤 재시도에 성공하며 늦은 이전 응답은 무시한다', (tester) async {
    final service = _ControlledMovieService();
    final router = _router(service);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 4900));
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('요청 시간이 초과되었습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('TimeoutException'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    service.requests.last.complete([movies.last]);
    await tester.pumpAndSettle();
    expect(_movieIds(tester), [6]);
    service.requests.first.complete([movies.first]);
    await tester.pumpAndSettle();
    expect(_movieIds(tester), [6]);
  });

  testWidgets('정렬은 재요청 없이 적용되고 새 화면에서 장르와 함께 복원된다', (tester) async {
    final service = _ControlledMovieService();
    var router = _router(service);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    service.requests.single.complete(movies);
    await tester.pumpAndSettle();

    await _selectSort(tester, '평점 높은순');
    expect(_movieIds(tester), [6, 3, 1, 4, 2, 5]);
    await _selectSort(tester, '제목순');
    await tester.tap(find.widgetWithText(FilterChip, '드라마'));
    await tester.pumpAndSettle();
    expect(_movieIds(tester), [4, 1]);
    expect(await SortPreference().read(), MovieSortOrder.title);
    expect(service.requests, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    router = _router(service);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    service.requests.last.complete(movies);
    await tester.pumpAndSettle();
    expect(_movieIds(tester), [4, 1]);
    expect(find.text('제목순'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '드라마'))
          .selected,
      isTrue,
    );

    // 갱신해도 선택한 필터와 정렬은 유지된다.
    final refresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pump();
    service.requests.last.complete(movies);
    await tester.pumpAndSettle();
    await refresh;
    expect(_movieIds(tester), [4, 1]);
  });
}
