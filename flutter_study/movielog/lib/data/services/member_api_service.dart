import 'package:dio/dio.dart';

import 'member_check_service.dart';

class MemberApiException implements Exception {
  const MemberApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class MemberRating {
  const MemberRating({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });
  final int ratingId;
  final int movieId;
  final int score;
  final String? comment;
  final DateTime createdAt;

  factory MemberRating.fromJson(Map<String, dynamic> json) => MemberRating(
    ratingId: (json['ratingId'] as num).toInt(),
    movieId: (json['movieId'] as num).toInt(),
    score: (json['score'] as num).toInt(),
    comment: json['comment'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class MemberRatingPage {
  const MemberRatingPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });
  final List<MemberRating> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  factory MemberRatingPage.fromJson(Map<String, dynamic> json) =>
      MemberRatingPage(
        content: (json['content'] as List)
            .map(
              (item) =>
                  MemberRating.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
        page: (json['page'] as num).toInt(),
        size: (json['size'] as num).toInt(),
        totalElements: (json['totalElements'] as num).toInt(),
        totalPages: (json['totalPages'] as num).toInt(),
        first: json['first'] as bool,
        last: json['last'] as bool,
      );
}

class MemberApiService implements MemberAvailabilityService {
  MemberApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment(
                'BACKEND_URL',
                defaultValue: 'http://localhost:8080',
              ),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );
  final Dio _dio;

  @override
  Future<bool> checkNickname(String nickname) =>
      _check('/members/nickname/${Uri.encodeComponent(nickname)}');
  @override
  Future<bool> checkEmail(String email) =>
      _check('/members/email/${Uri.encodeComponent(email)}');

  Future<bool> _check(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final available = response.data?['available'];
      if (available is! bool) {
        throw const MemberApiException('서버 응답을 확인할 수 없습니다.');
      }
      return available;
    } on DioException catch (error) {
      throw _convertError(error);
    }
  }

  Future<MemberRatingPage> getRatings({
    required int memberId,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/members/$memberId/ratings',
        queryParameters: {'page': page, 'size': size},
      );
      return MemberRatingPage.fromJson(response.data!);
    } on DioException catch (error) {
      throw _convertError(error);
    }
  }

  MemberApiException _convertError(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (status == 400 && data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty && errors.first is Map) {
        return MemberApiException(
          errors.first['message']?.toString() ?? '입력값을 확인해주세요.',
          statusCode: status,
        );
      }
    }
    if (status == 404) {
      return const MemberApiException('존재하지 않는 회원입니다.', statusCode: 404);
    }
    return MemberApiException(
      '서버에 연결하지 못했습니다. 잠시 후 다시 시도해주세요.',
      statusCode: status,
    );
  }

  void close() => _dio.close(force: true);
}
