class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.secondaryGenre,
    required this.year,
    required this.durationMinutes,
    required this.posterAsset,
    required this.averageRating,
    required this.reviewCount,
    required this.moods,
  });

  final int id;
  final String title;
  final String genre;
  final String secondaryGenre;
  final int year;
  final int durationMinutes;
  final String posterAsset;
  final double averageRating;
  final int reviewCount;
  final List<String> moods;
}
