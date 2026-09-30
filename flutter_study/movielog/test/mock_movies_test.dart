import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';

void main() {
  test('영화 ID로 공통 Mock Movie를 찾는다', () {
    final movie = findMovieById(1);

    expect(movie, isNotNull);
    expect(movie?.title, '별빛 아래 우리');
  });

  test('존재하지 않거나 null인 ID에는 null을 반환한다', () {
    expect(findMovieById(999), isNull);
    expect(findMovieById(null), isNull);
  });
}
