import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/movie/tmdb_movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_list_empty.dart';
import 'package:movielog/movie/widgets/movie_request_error_dialog.dart';
import 'package:movielog/movie/widgets/movie_list_loading.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'support/tmdb_test_service.dart';

class _ControlledService extends TestTmdbService {
  Completer<void>? gate;
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    await gate?.future;
    return super.discoverMovies(page: page, genreIds: genreIds);
  }
}

void main() {
  testWidgets('loading disables all genre chips until Discover completes', (
    tester,
  ) async {
    final service = _ControlledService();
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: TmdbMovieListScreen()),
      ),
    );
    service.gate = Completer<void>();
    await tester.tap(find.widgetWithText(FilterChip, '액션'));
    await tester.pump();
    expect(find.byType(MovieListLoading), findsOneWidget);
    for (final chip in tester.widgetList<FilterChip>(find.byType(FilterChip))) {
      expect(chip.onSelected, isNull);
    }
    await vm.selectGenres([18]);
    expect(vm.selectedGenreIds, [28]);
    service.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(service.requests.last.genreIds, [28]);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '전체'))
          .onSelected,
      isNotNull,
    );
  });

  testWidgets(
    'Discover failure retries the same genre and renders an empty result',
    (tester) async {
      final service = TestTmdbService();
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: TmdbMovieListScreen()),
        ),
      );
      service.fail = true;
      await tester.tap(find.widgetWithText(FilterChip, '드라마'));
      await tester.pumpAndSettle();
      expect(find.byType(MovieRequestErrorDialog), findsOneWidget);
      service.fail = false;
      service.count = 0;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(MovieListEmpty), findsOneWidget);
      expect(service.requests.last.page, 1);
      expect(service.requests.last.genreIds, [18]);
      expect(tester.takeException(), isNull);
    },
  );
}
