import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_api_service.dart';
import '../data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

// Each field owns its request version, so concurrent checks cannot affect each other.
class _CheckField {
  String value = '';
  String? duplicate;
  String? error;
  int version = 0;
  CheckStatus status = CheckStatus.idle;
}

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberAvailabilityService _service;
  final _nickname = _CheckField();
  final _email = _CheckField();
  bool _disposed = false;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  CheckStatus get emailCheckStatus => _email.status;
  String? get nicknameErrorText => _nickname.error;
  String? get emailErrorText => _email.error;
  bool get canCheckNickname => _canCheck(_nickname);
  bool get canCheckEmail => _canCheck(_email);
  bool _canCheck(_CheckField field) =>
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated &&
      field.value.isNotEmpty;

  void onNicknameChanged(String value) => _change(_nickname, value, '닉네임');
  void onEmailChanged(String value) => _change(_email, value, '이메일');

  void _change(_CheckField field, String value, String label) {
    if (_disposed) return;
    field.value = value.trim();
    field.version++;
    final duplicated =
        field.duplicate != null && field.value == field.duplicate;
    field.status = duplicated ? CheckStatus.duplicated : CheckStatus.idle;
    field.error = duplicated ? '이미 사용 중인 $label입니다.' : null;
    notifyListeners();
  }

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, '닉네임', _service.checkNickname);
  Future<void> checkEmail(String value) =>
      _check(_email, value, '이메일', _service.checkEmail);

  Future<void> _check(
    _CheckField field,
    String value,
    String label,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (_disposed || requested != field.value || !_canCheck(field)) return;
    final version = ++field.version;
    bool isCurrent() => !_disposed && version == field.version;
    field.status = CheckStatus.checking;
    field.error = null;
    notifyListeners();
    try {
      final available = await request(requested);
      if (!isCurrent()) return;
      field.status = available ? CheckStatus.available : CheckStatus.duplicated;
      field.error = available ? null : '이미 사용 중인 $label입니다.';
      if (!available) field.duplicate = requested;
    } on DioException {
      if (!isCurrent()) return;
      field.status = CheckStatus.error;
      field.error = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    } on MemberApiException catch (error) {
      // Compatibility with the earlier local-backend exercise's injected service.
      if (!isCurrent()) return;
      field.status = CheckStatus.error;
      field.error = error.message;
    }
    if (isCurrent()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
