import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/check_result.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

abstract interface class MemberAvailabilityService {
  Future<bool> checkNickname(String nickname);
  Future<bool> checkEmail(String email);
}

class SignUpService implements MemberAvailabilityService {
  SignUpService(this._dio);
  final Dio _dio;

  @override
  Future<bool> checkNickname(String nickname) =>
      _check('/v6/members/nickname/${Uri.encodeComponent(nickname.trim())}');

  @override
  Future<bool> checkEmail(String email) =>
      _check('/v6/members/email/${Uri.encodeComponent(email.trim())}');

  Future<bool> _check(String path) async {
    final response = await _dio.get(path);
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());
    if (response.statusCode != 201) throw StateError('회원가입 응답 계약 오류');
    final common = CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
    if (!common.isSuccess) throw StateError('회원가입 성공 응답을 확인하지 못했습니다.');
    return common;
  }
}

// HTML/proxy errors must not replace a recoverable UI with a parsing exception.
String writeSignUpErrorMessage(DioException error) =>
    apiErrorMessage(error, fallback: '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.');

String apiErrorMessage(DioException error, {required String fallback}) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    try {
      final response = CommonResponse<Object?>.fromJson(data, (value) => value);
      if (response.message.trim().isNotEmpty) return response.message;
    } on Object {
      /* A malformed error body uses the safe fallback. */
    }
  }
  return fallback;
}
