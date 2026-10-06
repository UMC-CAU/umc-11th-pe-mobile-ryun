import 'movie.dart';

enum MovieSortOrder {
  original('기본순'),
  rating('평점 높은순'),
  newest('최신순'),
  title('제목순');

  const MovieSortOrder(this.label);

  final String label;

  List<Movie> apply(List<Movie> movies) {
    // 원본 Mock 목록과 Future의 결과를 변경하지 않는다.
    final sorted = List<Movie>.of(movies);
    if (this == original) return sorted;
    sorted.sort((a, b) {
      final comparison = switch (this) {
        original => 0,
        rating => b.averageRating.compareTo(a.averageRating),
        newest => b.year.compareTo(a.year),
        title => a.title.compareTo(b.title),
      };
      return comparison == 0 ? a.id.compareTo(b.id) : comparison;
    });
    return sorted;
  }
}
