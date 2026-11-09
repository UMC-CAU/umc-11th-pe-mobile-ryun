import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import '../models/common_response.dart';
import 'sign_up_service.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    return (response.data as List<dynamic>)
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    _checkWrite(response, 201);
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    if ((comment?.trim().length ?? 0) > 500) {
      throw ArgumentError('코멘트는 500자 이하입니다.');
    }
    final response = await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {
        'score': score,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      },
    );
    _checkWrite(response, 200);
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    // A successful 204 has no JSON body.
    if (response.statusCode != 204) throw StateError('삭제 응답 계약 오류');
  }

  void _checkWrite(Response<dynamic> response, int status) {
    if (response.statusCode != status) throw StateError('평점 응답 계약 오류');
    final common = CommonResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => value,
    );
    if (!common.isSuccess) throw StateError('평점 저장 성공을 확인하지 못했습니다.');
  }
}

String writeErrorMessage(DioException error) => apiErrorMessage(
  error,
  fallback: switch (error.response?.statusCode) {
    400 => '평점이나 코멘트의 입력 형식을 확인해 주세요.',
    403 => '이 평점을 수정하거나 삭제할 권한이 없습니다.',
    404 => '요청한 회원 또는 평점을 찾을 수 없습니다.',
    409 => '이미 등록된 평점이 있습니다. 내 평점 목록을 확인해 주세요.',
    _ => '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
  },
);

bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code'] : null;
  final status = error.response?.statusCode;
  return status == 403 ||
      status == 404 ||
      code == 'COMMON403' ||
      code == 'COMMON404';
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
