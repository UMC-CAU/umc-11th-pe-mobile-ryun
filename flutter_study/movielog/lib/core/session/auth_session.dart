import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/safe_notify.dart';
import '../config/study_config.dart';

abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String? token);
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({this.key = 'movielog.$workbookVersion.accessToken'});
  final String key;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  @override
  Future<String?> read() => _storage.read(key: key);
  @override
  Future<void> write(String? token) => token == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: token);
}

enum MemberLoadStatus { idle, loading, ready, error }

class AuthSession extends ChangeNotifier with SafeNotify {
  AuthSession(this.publicClient, this.storage);
  final Dio publicClient;
  final TokenStorage storage;
  String? _token;
  String? get token => _token;
  String? email;
  String? nickname;
  DateTime? createdAt;
  int generation = 0;
  bool busy = false;
  bool initialized = false;
  bool restoreFailed = false;
  bool storageCleanupInProgress = false;
  bool cleanupFailed = false;
  bool sessionExpired = false;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? notice;
  bool get authenticated => _token != null && email != null;
  Future<void> _storageQueue = Future.value();
  Future<void> _store(String? value) {
    final next = _storageQueue.then((_) => storage.write(value));
    _storageQueue = next.catchError((Object _) {});
    return next;
  }

  bool current(int version) => !isDisposed && generation == version;
  void _clearMember() {
    _token = null;
    email = null;
    nickname = null;
    createdAt = null;
    memberStatus = MemberLoadStatus.idle;
  }

  void _setMember(Object? data) {
    final info = data as Map<String, dynamic>;
    email = info['email'] as String;
    nickname = info['nickname'] as String;
    createdAt = DateTime.tryParse(info['createdAt'] as String? ?? '');
    memberStatus = MemberLoadStatus.ready;
  }

  Future<Response<dynamic>> _me(String token) => publicClient.get(
    '/$workbookVersion/members/me',
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
      followRedirects: false,
    ),
  );
  Future<void> restore() async {
    if (busy || storageCleanupInProgress) return;
    final version = ++generation;
    busy = true;
    restoreFailed = false;
    initialized = false;
    notice = null;
    _clearMember();
    notifyIfAlive();
    try {
      if (cleanupFailed) {
        await _store(null);
        cleanupFailed = false;
      }
      final saved = await storage.read();
      if (!current(version) || saved == null) return;
      final response = await _me(saved);
      if (!current(version)) return;
      _setMember(unwrap(response.data));
      _token = saved;
    } on DioException catch (error) {
      if (!current(version)) return;
      if (isSessionExpired(error)) {
        sessionExpired = true;
        try {
          await _store(null);
        } on Object {
          cleanupFailed = true;
          restoreFailed = true;
        }
        notice = cleanupFailed
            ? '만료된 로그인 정보를 지우지 못했습니다. 다시 시도해 주세요.'
            : '로그인이 만료됐어요. 다시 로그인해 주세요.';
      } else {
        restoreFailed = true;
        notice = '세션을 확인하지 못했습니다. 연결 확인 후 다시 시도해 주세요.';
      }
    } on Object {
      if (current(version)) {
        restoreFailed = true;
        notice = '저장소 또는 세션 응답을 확인하지 못했습니다. 다시 시도해 주세요.';
      }
    } finally {
      if (current(version)) {
        busy = false;
        initialized = true;
        notifyIfAlive();
      }
    }
  }

  Future<void> login(String inputEmail, String password) async {
    if (busy || storageCleanupInProgress || cleanupFailed) return;
    final version = ++generation;
    _clearMember();
    busy = true;
    notice = null;
    sessionExpired = false;
    restoreFailed = false;
    notifyIfAlive();
    try {
      await _store(null);
      if (!current(version)) return;
      final response = await publicClient.post(
        '/$workbookVersion/auth/login',
        data: {'email': inputEmail.trim(), 'password': password},
      );
      if (!current(version)) return;
      final result = unwrap(response.data) as Map<String, dynamic>;
      final nextToken = result['accessToken'] as String;
      if (nextToken.isEmpty) throw StateError('빈 토큰');
      // New login saves its token first; MainScreen independently loads GET me.
      await _store(nextToken);
      if (!current(version)) return;
      _token = nextToken;
      email = inputEmail.trim();
      nickname = result['nickname'] as String?;
      memberStatus = MemberLoadStatus.idle;
    } finally {
      if (current(version)) {
        busy = false;
        initialized = true;
        notifyIfAlive();
      }
    }
  }

  Future<void> loadMember() async {
    final saved = _token;
    if (saved == null || memberStatus == MemberLoadStatus.loading) return;
    final version = generation;
    memberStatus = MemberLoadStatus.loading;
    notifyIfAlive();
    try {
      final response = await _me(saved);
      if (current(version)) _setMember(unwrap(response.data));
    } on DioException catch (error) {
      if (!current(version)) return;
      if (isSessionExpired(error)) {
        await expire(version);
      } else {
        memberStatus = MemberLoadStatus.error;
      }
    } on Object {
      if (current(version)) memberStatus = MemberLoadStatus.error;
    }
    if (current(version)) notifyIfAlive();
  }

  Future<void> updateNickname(Dio authClient, String value) async {
    final name = value.trim();
    if (name.length < 2 || name.length > 12) {
      throw ArgumentError('닉네임은 2~12자로 입력해 주세요.');
    }
    final version = generation;
    final response = await authClient.patch(
      '/$workbookVersion/members/me',
      data: {'nickname': name},
    );
    if (!current(version)) return;
    _setMember(unwrap(response.data));
    notifyIfAlive();
  }

  void consumeSessionExpired() {
    sessionExpired = false;
  }

  Future<void> logout({String? message}) async {
    final version = ++generation;
    _clearMember();
    busy = false;
    initialized = true;
    restoreFailed = false;
    notice = message;
    storageCleanupInProgress = true;
    notifyIfAlive();
    try {
      await _store(null);
      if (current(version)) cleanupFailed = false;
    } on Object {
      if (current(version)) {
        cleanupFailed = true;
        notice = '로그아웃했습니다. 기기 저장소 정리는 다시 시도해 주세요.';
      }
      rethrow;
    } finally {
      if (current(version)) {
        storageCleanupInProgress = false;
        notifyIfAlive();
      }
    }
  }

  Future<void> expire(int version) async {
    if (!current(version) || !authenticated) return;
    sessionExpired = true;
    try {
      await logout(message: '로그인이 만료됐어요. 다시 로그인해 주세요.');
    } on Object {
      /* Memory remains cleared. */
    }
  }
}

Object? unwrap(dynamic data) {
  final body = data as Map<String, dynamic>;
  if (body['isSuccess'] != true) throw StateError('API 성공을 확인하지 못했습니다.');
  return body['result'];
}

String? errorCode(DioException error) {
  final body = error.response?.data;
  return body is Map ? body['code'] as String? : null;
}

bool isSessionExpired(DioException error) =>
    error.response?.statusCode == 401 &&
    {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(errorCode(error));
