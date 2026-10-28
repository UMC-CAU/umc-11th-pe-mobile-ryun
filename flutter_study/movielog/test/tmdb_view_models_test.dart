import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'support/tmdb_test_service.dart';

void main() {
  test(
    'popular takes five and handles short, empty, and failed results',
    () async {
      final service = TestTmdbService();
      final vm = MovieHomeViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadPopular();
      expect(vm.popularMovies.length, 5);
      service.count = 2;
      await vm.loadPopular();
      expect(vm.popularMovies.length, 2);
      service.count = 0;
      await vm.loadPopular();
      expect(vm.status, MovieHomeLoadStatus.empty);
      service.fail = true;
      await vm.loadPopular();
      expect(vm.status, MovieHomeLoadStatus.error);
      service.fail = false;
      await vm.loadPopular();
      expect(vm.message, isNull);
    },
  );

  test(
    'Discover deduplicates pages and restarts page one for a genre',
    () async {
      final service = TestTmdbService();
      final vm = MovieListViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      expect(vm.movies.length, 30);
      expect(vm.movies.map((m) => m.id).toSet().length, 30);
      expect(service.requests.map((r) => r.page), [1, 2]);
      await vm.selectGenres([28]);
      expect(service.requests[2].page, 1);
      expect(service.requests[2].genreIds, [28]);
      await vm.selectGenres(null);
      expect(service.requests[4], (page: 1, genreIds: null));
    },
  );

  test('loading blocks genre changes and overlapping requests', () async {
    final service = TestTmdbService();
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    final loading = vm.loadInitial();
    expect(vm.status, MovieListLoadStatus.loading);
    await vm.selectGenres([28]);
    await vm.loadInitial();
    expect(vm.selectedGenreIds, isNull);
    await loading;
    expect(service.requests.length, 2);
  });

  test('short and empty Discover results stop, retry keeps genre', () async {
    final service = TestTmdbService()..count = 2;
    final vm = MovieListViewModel(service);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    expect(vm.movies.length, 2);
    expect(service.requests.length, 1);
    service.fail = true;
    await vm.selectGenres([28]);
    expect(vm.status, MovieListLoadStatus.error);
    service.fail = false;
    service.count = 0;
    await vm.loadInitial();
    expect(vm.status, MovieListLoadStatus.empty);
    expect(service.requests.last.page, 1);
    expect(service.requests.last.genreIds, [28]);
  });

  test('disposing during a request prevents later notifications', () async {
    final service = TestTmdbService();
    final home = MovieHomeViewModel(service);
    final list = MovieListViewModel(service);
    final homeLoad = home.loadPopular();
    final listLoad = list.loadInitial();
    home.dispose();
    list.dispose();
    await Future.wait([homeLoad, listLoad]);
    expect(service.requests, isEmpty);
  });
}
