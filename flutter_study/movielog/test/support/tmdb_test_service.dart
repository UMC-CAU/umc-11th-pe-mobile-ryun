import 'package:dio/dio.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

TmdbMovieDto testMovie(int id) => TmdbMovieDto.fromJson({
  'id': id,
  'title': 'TMDB 영화 $id',
  'overview': '줄거리 $id',
});

class TestTmdbService extends TmdbMovieService {
  TestTmdbService() : super(Dio());
  int popularCalls = 0;
  final requests = <({int page, List<int>? genreIds})>[];
  bool fail = false;
  int count = 40;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    popularCalls++;
    if (fail) throw Exception('Test failure');
    return TmdbMoviePageDto(
      page: page,
      results: List.generate(count, (i) => testMovie(i + 1000)),
      totalPages: 1,
      totalResults: count,
    );
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [
    TmdbGenreDto(id: 28, name: '액션'),
    TmdbGenreDto(id: 18, name: '드라마'),
  ];

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    requests.add((page: page, genreIds: genreIds));
    if (fail) throw Exception('Test failure');
    // 페이지 사이 ID 1019가 겹치는 응답.
    final ids = page == 1
        ? List.generate(count < 20 ? count : 20, (i) => i + 1000)
        : List.generate(20, (i) => i + 1019);
    return TmdbMoviePageDto(
      page: page,
      results: ids.map(testMovie).toList(),
      totalPages: count < 20 ? 1 : 2,
      totalResults: count,
    );
  }
}
