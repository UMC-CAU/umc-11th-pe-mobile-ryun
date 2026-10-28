import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/movie/tmdb_movie_list_screen.dart';
import 'package:movielog/movie/widgets/genre_filter_sheet.dart';
import 'package:movielog/movie/widgets/movie_request_error_dialog.dart';
import 'package:movielog/movie/widgets/tmdb_movie_card.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'support/tmdb_test_service.dart';

class _Service extends TestTmdbService {
  Completer<void>? gate;
  int offset = 0;
  int? failPage;
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    await gate?.future;
    if (page == failPage) throw Exception('Test offline');
    final result = await super.discoverMovies(page: page, genreIds: genreIds);
    return TmdbMoviePageDto(
      page: result.page,
      totalPages: result.totalPages,
      totalResults: result.totalResults,
      results: result.results.map((m) => testMovie(m.id + offset)).toList(),
    );
  }
}

Widget _screen(MovieListViewModel vm) => ChangeNotifierProvider.value(
  value: vm,
  child: const MaterialApp(home: TmdbMovieListScreen()),
);

void main() {
  test('refresh keeps old results until every page succeeds, rollback on page two failure', () async {
    final service = _Service();
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.selectGenres([28, 18, 28]);
    expect(vm.selectedGenreIds, [18, 28]);
    final saved = vm.movies;
    service.offset = 5000;
    service.gate = Completer<void>();
    final refresh = vm.refresh();
    expect(vm.isLoading, isTrue);
    expect(identical(vm.movies, saved), isTrue);
    await vm.refresh();
    await vm.selectGenres([18]);
    expect(vm.selectedGenreIds, [18, 28]);
    service.gate!.complete();
    await refresh;
    expect(vm.movies.first.id, 6000);
    expect(service.requests[2].page, 1);
    expect(service.requests[2].genreIds, [18, 28]);

    final latest = vm.movies;
    service.failPage = 2;
    await vm.refresh();
    expect(vm.status, MovieListLoadStatus.error);
    expect(identical(vm.movies, latest), isTrue);
    expect(vm.errorDialogPending, isTrue);
    service.failPage = null;
    final start = service.requests.length;
    await vm.retry();
    expect(service.requests[start].page, 1);
    expect(service.requests[start].genreIds, [18, 28]);
    expect(vm.errorDialogPending, isFalse);
  });

  test('failed genre change restores successful list; cancel restores its genre labels', () async {
    final service = _Service();
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.selectGenres([28]);
    final saved = vm.movies;
    service.fail = true;
    await vm.selectGenres([18]);
    expect(identical(vm.movies, saved), isTrue);
    expect(vm.selectedGenreIds, [18]);
    vm.cancelError();
    expect(vm.selectedGenreIds, [28]);
    expect(vm.status, MovieListLoadStatus.success);
    expect(vm.errorDialogPending, isFalse);
  });

  testWidgets(
    'BottomSheet drafts multiple IDs, dismiss cancels, confirm empty selects all',
    (tester) async {
      final service = _Service();
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      await tester.pumpWidget(_screen(vm));
      final before = service.requests.length;
      await tester.tap(find.byKey(const Key('genreFilterButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, '액션'));
      await tester.tap(find.widgetWithText(CheckboxListTile, '드라마'));
      expect(service.requests.length, before);
      await tester.tap(find.byKey(const Key('applyGenreFilterButton')));
      await tester.pumpAndSettle();
      expect(vm.selectedGenreIds, [18, 28]);
      final confirmed = service.requests.length;
      await tester.tap(find.byKey(const Key('genreFilterButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, '액션'));
      Navigator.of(tester.element(find.byType(GenreFilterSheet))).pop();
      await tester.pumpAndSettle();
      expect(vm.selectedGenreIds, [18, 28]);
      expect(service.requests.length, confirmed);
      await tester.tap(find.byKey(const Key('genreFilterButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, '액션'));
      await tester.tap(find.widgetWithText(CheckboxListTile, '드라마'));
      await tester.tap(find.byKey(const Key('applyGenreFilterButton')));
      await tester.pumpAndSettle();
      expect(vm.selectedGenreIds, isNull);
      expect(service.requests.last.genreIds, isNull);
    },
  );

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets(
      'pull refresh with $kind keeps cards, blocks overlapping gesture, and replaces latest list',
      (tester) async {
        final service = _Service();
        final vm = MovieListViewModel(service);
        addTearDown(vm.dispose);
        await vm.selectGenres([18, 28]);
        await tester.pumpWidget(_screen(vm));
        service.gate = Completer<void>();
        service.offset = 5000;
        await tester.drag(
          find.byType(GridView),
          const Offset(0, 500),
          kind: kind,
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(vm.isLoading, isTrue);
        expect(
          tester
              .widget<TmdbMovieCard>(find.byType(TmdbMovieCard).first)
              .movie
              .id,
          1000,
        );
        final predicate = tester
            .widget<RefreshIndicator>(find.byType(RefreshIndicator))
            .notificationPredicate;
        final scrollableContext = tester.element(find.byType(GridView));
        expect(
          predicate(
            ScrollUpdateNotification(
              metrics: FixedScrollMetrics(
                minScrollExtent: 0,
                maxScrollExtent: 1000,
                pixels: 0,
                viewportDimension: 600,
                axisDirection: AxisDirection.down,
                devicePixelRatio: 1,
              ),
              context: scrollableContext,
            ),
          ),
          isFalse,
        );
        final requestCount = service.requests.length;
        await tester.drag(
          find.byType(GridView),
          const Offset(0, 500),
          kind: kind,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(service.requests.length, requestCount);
        service.gate!.complete();
        await tester.pumpAndSettle();
        expect(vm.movies.first.id, 6000);
        expect(vm.selectedGenreIds, [18, 28]);
      },
    );
  }

  testWidgets(
    'offline refresh dialog retains grid; cancel and repeated retry recover',
    (tester) async {
      final service = _Service();
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.selectGenres([18, 28]);
      await tester.pumpWidget(_screen(vm));
      service.fail = true;
      await vm.refresh();
      await tester.pumpAndSettle();
      expect(find.byType(MovieRequestErrorDialog), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(vm.movies.length, 30);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(MovieRequestErrorDialog), findsNothing);
      await vm.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(MovieRequestErrorDialog), findsOneWidget);
      service.fail = false;
      service.offset = 5000;
      final start = service.requests.length;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(MovieRequestErrorDialog), findsNothing);
      expect(service.requests[start].page, 1);
      expect(service.requests[start].genreIds, [18, 28]);
      expect(vm.movies.first.id, 6000);
    },
  );
}
