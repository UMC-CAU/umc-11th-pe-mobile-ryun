import 'tmdb_movie_dto.dart';
import 'rating_dto.dart';
import 'rating_request.dart';

class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });
  final int favoriteId;
  final int movieId;
  final DateTime createdAt;
  factory FavoriteResponseDto.fromJson(Map<String, dynamic> json) =>
      FavoriteResponseDto(
        favoriteId: (json['favoriteId'] as num).toInt(),
        movieId: (json['movieId'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class FavoriteCheckDto {
  const FavoriteCheckDto(this.movieId, this.isFavorite);
  final int movieId;
  final bool isFavorite;
  factory FavoriteCheckDto.fromJson(
    Map<String, dynamic> json, {
    required int movieId,
  }) => FavoriteCheckDto(movieId, json['isFavorite'] as bool);
}

class FavoriteListItem {
  const FavoriteListItem(this.favorite, this.movie);
  final FavoriteResponseDto favorite;
  final TmdbMovieDto? movie;
}

class CreateMovieRecordRequest {
  CreateMovieRecordRequest({
    required this.movieId,
    required this.score,
    this.comment,
    required this.addToFavorites,
  }) {
    if (movieId < 1) throw ArgumentError.value(movieId);
    validateServerScore(score.toDouble());
  }
  final int movieId;
  final int score;
  final String? comment;
  final bool addToFavorites;
  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    if (comment?.trim().isNotEmpty == true) 'comment': comment!.trim(),
    'addToFavorites': addToFavorites,
  };
}

class MovieRecordResponse {
  const MovieRecordResponse(this.rating, this.favorite);
  final RatingDto rating;
  final FavoriteResponseDto? favorite;
  factory MovieRecordResponse.fromJson(Map<String, dynamic> json) =>
      MovieRecordResponse(
        RatingDto.fromJson(json['rating'] as Map<String, dynamic>),
        json['favorite'] == null
            ? null
            : FavoriteResponseDto.fromJson(
                json['favorite'] as Map<String, dynamic>,
              ),
      );
}
