import 'package:dio/dio.dart';

import '../../core/session/auth_session.dart';
import '../models/favorite_models.dart';

abstract interface class FavoriteApi {
  Future<List<FavoriteResponseDto>> fetchFavorites();
  Future<FavoriteCheckDto> check(int movieId);
  Future<FavoriteResponseDto> add(int movieId);
  Future<void> remove(int movieId);
  Future<MovieRecordResponse> saveRecord(CreateMovieRecordRequest request);
}

class FavoriteApiService implements FavoriteApi {
  FavoriteApiService(this.dio);
  final Dio dio;
  @override
  Future<List<FavoriteResponseDto>> fetchFavorites() async {
    final response = await dio.get('/v8/favorites');
    return (unwrap(response.data) as List)
        .map(
          (item) => FavoriteResponseDto.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<FavoriteCheckDto> check(int movieId) async {
    final response = await dio.get('/v8/favorites/$movieId');
    return FavoriteCheckDto.fromJson(
      unwrap(response.data) as Map<String, dynamic>,
      movieId: movieId,
    );
  }

  @override
  Future<FavoriteResponseDto> add(int movieId) async {
    final response = await dio.post(
      '/v8/favorites',
      data: {'movieId': movieId},
    );
    return FavoriteResponseDto.fromJson(
      unwrap(response.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> remove(int movieId) async {
    final response = await dio.delete('/v8/favorites/$movieId');
    if (response.statusCode != 200 || unwrap(response.data) != null) {
      throw StateError('즐겨찾기 해제 응답 계약 오류');
    }
  }

  @override
  Future<MovieRecordResponse> saveRecord(
    CreateMovieRecordRequest request,
  ) async {
    final response = await dio.post(
      '/v8/movie-records',
      data: request.toJson(),
    );
    return MovieRecordResponse.fromJson(
      unwrap(response.data) as Map<String, dynamic>,
    );
  }
}
