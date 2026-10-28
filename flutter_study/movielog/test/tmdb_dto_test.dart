import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';

void main() {
  test('decodes a page with integer and decimal movie scores', () {
    final json = jsonDecode('''
      {
        "page": 1,
        "total_pages": 2,
        "total_results": 3,
        "results": [
          {"id": 550, "vote_average": 8, "popularity": 120.5},
          {"id": 551, "vote_average": 7.5, "popularity": 100}
        ]
      }
    ''') as Map<String, dynamic>;

    final page = TmdbMoviePageDto.fromJson(json);

    expect(page.results.map((movie) => movie.id), [550, 551]);
    expect(page.results.map((movie) => movie.voteAverage), [8.0, 7.5]);
    expect(page.results.last.popularity, isA<double>());
    expect(page.page < page.totalPages, isTrue);
  });

  test('allows missing or null optional movie data', () {
    for (final json in <Map<String, dynamic>>[
      {'id': 550},
      {'id': 550, 'title': null, 'overview': null, 'genre_ids': null},
    ]) {
      final movie = TmdbMovieDto.fromJson(json);

      expect(movie.title, '제목 없음');
      expect(movie.overview, isEmpty);
      expect(movie.posterPath, isNull);
      expect(movie.backdropPath, isNull);
      expect(movie.releaseDate, isNull);
      expect(movie.genreIds, isEmpty);
      expect(movie.voteAverage, 0.0);
    }
  });

  test('empty page can safely supply fewer than five popular movies', () {
    final page = TmdbMoviePageDto.fromJson({
      'page': 1,
      'results': [],
      'total_pages': 0,
      'total_results': 0,
    });

    expect(page.results.take(5), isEmpty);
  });
}
