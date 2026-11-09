import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/models/create_member_request.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

enum SubmitStatus { idle, submitting, success, error }

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
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;
  bool get isSubmitting => submitStatus == SubmitStatus.submitting;
  bool get canSubmit =>
      !isSubmitting &&
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;

  void onPasswordChanged() {
    passwordErrorText = null;
    snackbarMessage = null;
    if (!isSubmitting) submitStatus = SubmitStatus.idle;
    if (!_disposed) notifyListeners();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (_disposed ||
        !canSubmit ||
        request.nickname.trim() != _nickname.value ||
        request.email.trim() != _email.value) {
      return;
    }
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();
    try {
      final service = _service;
      if (service is! SignUpService) throw StateError('회원가입 Service가 필요합니다.');
      final response = await service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (!response.isSuccess || id == null || id < 1) {
        throw StateError('회원가입 결과에 memberId가 없습니다.');
      }
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      if (error.response?.statusCode == 400 &&
          RegExp(r'비밀번호.*(형식|특수문자|자 이상)').hasMatch(message)) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } on Object {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  CheckStatus get nicknameCheckStatus => _nickname.status;
  CheckStatus get emailCheckStatus => _email.status;
  String? get nicknameErrorText => _nickname.error;
  String? get emailErrorText => _email.error;
  bool get canCheckNickname => _canCheck(_nickname);
  bool get canCheckEmail => _canCheck(_email);
  bool _canCheck(_CheckField field) =>
      !isSubmitting &&
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated &&
      field.value.isNotEmpty;

  void onNicknameChanged(String value) => _change(_nickname, value, '닉네임');
  void onEmailChanged(String value) => _change(_email, value, '이메일');

  void _change(_CheckField field, String value, String label) {
    if (_disposed || isSubmitting) return;
    snackbarMessage = null;
    passwordErrorText = null;
    createdMemberId = null;
    submitStatus = SubmitStatus.idle;
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
    } on Object {
      if (!isCurrent()) return;
      field.status = CheckStatus.error;
      field.error = '중복 확인 결과를 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (isCurrent()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
