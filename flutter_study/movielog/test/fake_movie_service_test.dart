import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  test('success는 기존 Mock 영화 목록을 반환한다', () async {
    const service = FakeMovieService();
    expect(await service.fetchMovies(), movies);
  });

  test('empty는 정상적인 빈 목록으로 완료된다', () async {
    const service = FakeMovieService(mode: MovieLoadMode.empty);
    expect(await service.fetchMovies(), isEmpty);
  });

  test('failure는 MovieLoadException으로 완료된다', () async {
    const service = FakeMovieService(mode: MovieLoadMode.failure);
    await expectLater(
      service.fetchMovies(),
      throwsA(isA<MovieLoadException>()),
    );
  });

  test('시연용 서비스는 첫 요청만 실패하고 재시도부터 성공한다', () async {
    final service = FirstAttemptFailsMovieService(responseDelay: Duration.zero);
    await expectLater(
      service.fetchMovies(),
      throwsA(isA<MovieLoadException>()),
    );
    expect(await service.fetchMovies(), movies);
    expect(await service.fetchMovies(), movies);
  });
}
