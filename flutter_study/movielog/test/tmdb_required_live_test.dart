import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('real Genre and Discover: all, selected genre, and all again', () async {
    await dotenv.load(fileName: '.env');
    final token = TmdbConfig.accessToken;
    expect(token.isNotEmpty, isTrue);
    final logs = <String>[];
    final originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
    addTearDown(() => debugPrint = originalPrint);
    final dio = createTmdbClient();
    addTearDown(() => dio.close(force: true));
    final requests = <RequestOptions>[];
    final statuses = <int?>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          statuses.add(response.statusCode);
          handler.next(response);
        },
      ),
    );
    final vm = MovieListViewModel(TmdbMovieService(dio));
    addTearDown(vm.dispose);

    await HttpOverrides.runWithHttpOverrides(() async {
      await vm.loadInitial();
      expect(vm.status, MovieListLoadStatus.success);
      expect(vm.genres, isNotEmpty);
      expect(vm.movies.length, 30);
      expect(vm.movies.map((m) => m.id).toSet().length, 30);
      expect(requests.first.path, '/genre/movie/list');
      expect(requests[1].queryParameters['page'], 1);
      expect(requests[1].queryParameters.containsKey('with_genres'), isFalse);
      originalPrint(
        '[Required] all: genres=${vm.genres.length}, uniqueMovies=${vm.movies.length}',
      );

      final genre = vm.genres.first;
      final genreStart = requests.length;
      await vm.selectGenres([genre.id]);
      expect(vm.status, MovieListLoadStatus.success);
      expect(vm.movies, isNotEmpty);
      expect(vm.movies.length, lessThanOrEqualTo(30));
      expect(vm.movies.every((m) => m.genreIds.contains(genre.id)), isTrue);
      expect(requests[genreStart].queryParameters['page'], 1);
      expect(
        requests[genreStart].queryParameters['with_genres'],
        genre.id.toString(),
      );
      originalPrint(
        '[Required] genre=${genre.id}: uniqueMovies=${vm.movies.length}, genreMatch=true',
      );

      final allStart = requests.length;
      await vm.selectGenres(null);
      expect(vm.status, MovieListLoadStatus.success);
      expect(requests[allStart].queryParameters['page'], 1);
      expect(
        requests[allStart].queryParameters.containsKey('with_genres'),
        isFalse,
      );
      originalPrint(
        '[Required] all again: uniqueMovies=${vm.movies.length}, with_genres omitted=true',
      );

      final multiStart = requests.length;
      await vm.selectGenres([18, 28]);
      expect(vm.status, MovieListLoadStatus.success);
      expect(requests[multiStart].queryParameters['page'], 1);
      expect(requests[multiStart].queryParameters['with_genres'], '18|28');
      expect(
        vm.movies.every((movie) => movie.genreIds.any([18, 28].contains)),
        isTrue,
      );
      originalPrint(
        '[Challenge] with_genres=18|28, uniqueMovies=${vm.movies.length}, OR match=true',
      );
      final beforeRefresh = requests.length;
      await vm.refresh();
      expect(vm.status, MovieListLoadStatus.success);
      expect(requests[beforeRefresh].queryParameters['page'], 1);
      expect(requests[beforeRefresh].queryParameters['with_genres'], '18|28');
      originalPrint(
        '[Challenge] refresh page=1, selectedGenreIds=${vm.selectedGenreIds}',
      );
    }, _RealHttpOverrides());

    expect(logs.any((line) => line.contains(token)), isFalse);
    expect(statuses, everyElement(200));
    for (final line in logs.where((line) => line.startsWith('[TMDB 응답]'))) {
      originalPrint(line.replaceAll(token, '***'));
    }
  }, skip: !const bool.fromEnvironment('TMDB_LIVE_TEST'));
}
