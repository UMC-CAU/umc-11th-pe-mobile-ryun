import 'package:dio/dio.dart';

import '../models/check_result.dart';

abstract interface class MemberAvailabilityService {
  Future<bool> checkNickname(String nickname);
  Future<bool> checkEmail(String email);
}

class MemberCheckService implements MemberAvailabilityService {
  MemberCheckService(this._dio);
  final Dio _dio;

  @override
  Future<bool> checkNickname(String nickname) =>
      _check('/v5/members/nickname/${Uri.encodeComponent(nickname.trim())}');
  @override
  Future<bool> checkEmail(String email) =>
      _check('/v5/members/email/${Uri.encodeComponent(email.trim())}');

  Future<bool> _check(String path) async {
    final response = await _dio.get(path);
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}
