import '../data/mock_movies.dart';
import '../models/movie.dart';

enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

class FakeMovieService {
  const FakeMovieService({
    this.mode = MovieLoadMode.success,
    this.responseDelay = const Duration(seconds: 1),
  });

  final MovieLoadMode mode;
  final Duration responseDelay;

  Future<List<Movie>> fetchMovies() async {
    // TODO(5주차 유저별 평점 조회 API): 지연과 Mock 응답을 실제 API 호출로 교체한다.
    await Future<void>.delayed(responseDelay);

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화 목록을 불러오지 못했습니다.',
      ),
    };
  }
}

// 시연용: 같은 인스턴스에서 첫 요청만 실패하고 재시도부터 성공한다.
class FirstAttemptFailsMovieService extends FakeMovieService {
  FirstAttemptFailsMovieService({super.responseDelay});

  int _requestCount = 0;

  @override
  Future<List<Movie>> fetchMovies() async {
    _requestCount++;
    await Future<void>.delayed(responseDelay);
    if (_requestCount == 1) {
      throw const MovieLoadException('영화 목록을 불러오지 못했습니다.');
    }
    return movies;
  }
}
