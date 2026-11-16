import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/config/study_config.dart';
import 'package:movielog/core/session/auth_session.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/models/rating_request.dart';

class Tokens implements TokenStorage {
  String? value;
  bool fail = false;
  bool failTokenWrite = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? token) async {
    if (fail || (failTokenWrite && token != null)) throw StateError('storage');
    value = token;
  }
}

Map<String, dynamic> success(Object? value) => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': '성공',
  'result': value,
};
Dio fixture(FutureOr<Object?> Function(RequestOptions) respond) =>
    Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) async {
            try {
              h.resolve(
                Response(
                  requestOptions: r,
                  statusCode: r.method == 'POST' && r.path.endsWith('ratings')
                      ? 201
                      : 200,
                  data: await respond(r),
                ),
              );
            } catch (e) {
              h.reject(
                e is DioException
                    ? e
                    : DioException(requestOptions: r, error: e),
              );
            }
          },
        ),
      );
DioException failure(RequestOptions r, int status, String code) => DioException(
  requestOptions: r,
  response: Response(
    requestOptions: r,
    statusCode: status,
    data: {'code': code},
  ),
);

class StatusAdapter implements HttpClientAdapter {
  String code = 'RATING403_1';
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({'code': code}),
    code == 'RATING403_1' ? 403 : 401,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'restore requires GET me; network error preserves secure token',
    () async {
      final tokens = Tokens()..value = 'test';
      final dio = fixture((r) => throw failure(r, 503, 'SERVER'));
      final s = AuthSession(dio, tokens);
      await s.restore();
      expect(s.authenticated, false);
      expect(s.restoreFailed, true);
      expect(tokens.value, 'test');
    },
  );
  test('restore invalid token deletes storage and expires once', () async {
    final tokens = Tokens()..value = 'test';
    final s = AuthSession(
      fixture((r) => throw failure(r, 401, 'AUTH401_3')),
      tokens,
    );
    await s.restore();
    expect(tokens.value, isNull);
    expect(s.sessionExpired, true);
    s.consumeSessionExpired();
    expect(s.sessionExpired, false);
  });
  test('login 401 is form failure, never session expired', () async {
    final s = AuthSession(
      fixture((r) => throw failure(r, 401, 'AUTH401_1')),
      Tokens(),
    );
    await expectLater(s.login('a', 'b'), throwsA(isA<DioException>()));
    expect(s.sessionExpired, false);
    expect(s.authenticated, false);
  });
  test('save failure cannot establish signed in state', () async {
    final tokens = Tokens()..failTokenWrite = true;
    final dio = fixture((r) {
      return success(
        r.path.endsWith('/login')
            ? {'accessToken': 'test'}
            : {'email': 'a', 'nickname': 'AA'},
      );
    });
    final s = AuthSession(dio, tokens);
    await expectLater(s.login('a', 'b'), throwsStateError);
    expect(s.authenticated, false);
  });
  test('logout while GET me waits cannot restore previous session', () async {
    final wait = Completer<Object?>();
    final tokens = Tokens()..value = 'test';
    final s = AuthSession(fixture((_) => wait.future), tokens);
    final restoring = s.restore();
    await Future<void>.delayed(Duration.zero);
    await s.logout();
    wait.complete(success({'email': 'a', 'nickname': 'AA'}));
    await restoring;
    expect(s.authenticated, false);
    expect(tokens.value, isNull);
  });
  test(
    '403 and 409 keep login; stale expiry cannot delete new session',
    () async {
      final s = AuthSession(
        fixture(
          (r) => success(
            r.path.endsWith('/login')
                ? {'accessToken': 'test'}
                : {'email': 'a', 'nickname': 'AA'},
          ),
        ),
        Tokens(),
      );
      await s.login('a', 'b');
      final old = s.generation;
      await s.login('b', 'b');
      await s.expire(old);
      expect(s.authenticated, true);
      expect(
        isSessionExpired(failure(RequestOptions(), 403, 'RATING403_1')),
        false,
      );
      expect(
        isSessionExpired(failure(RequestOptions(), 409, 'MEMBER409_1')),
        false,
      );
    },
  );
  test('auth host, version and public route boundary', () {
    final s = AuthSession(Dio(), Tokens());
    final i = AuthInterceptor(s);
    expect(
      i.protected(
        RequestOptions(
          baseUrl: 'https://workbook.devnoco.com',
          path: '/$workbookVersion/members/me',
        ),
      ),
      true,
    );
    expect(
      i.protected(
        RequestOptions(
          baseUrl: 'https://evil.invalid',
          path: '/$workbookVersion/ratings',
        ),
      ),
      false,
    );
    expect(
      i.protected(
        RequestOptions(
          baseUrl: 'https://workbook.devnoco.com',
          path: '/$workbookVersion/members/1/ratings',
        ),
      ),
      false,
    );
    if (week8) {
      expect(
        i.protected(
          RequestOptions(
            baseUrl: 'https://workbook.devnoco.com',
            path: '/v8/favorites',
          ),
        ),
        false,
      );
    }
  });
  test(
    'rating request uses JWT path and comment replacement; late cache blocked',
    () async {
      var generation = 1;
      final requests = <RequestOptions>[];
      final dio = fixture((r) {
        requests.add(r);
        return success({
          'ratingId': 1,
          'movieId': 550,
          'score': 4,
          'comment': 'kept',
          'createdAt': '2026-01-01T00:00:00Z',
        });
      });
      final api = RatingApiService(
        dio,
        authenticated: true,
        sessionVersion: () => generation,
      );
      await api.createRating(
        request: CreateRatingRequest(movieId: 550, score: 4, comment: 'kept'),
      );
      expect(requests.last.path, '/$workbookVersion/ratings');
      expect((requests.last.data as Map).containsKey('memberId'), false);
      await api.updateRating(ratingId: 1, score: 4, comment: 'kept');
      expect(requests.last.data, {'score': 4, 'comment': 'kept'});
      generation++;
      expect(await api.fetchMyRatings(0), isEmpty);
    },
  );
  test('nickname validation runs before request', () async {
    final s = AuthSession(
      fixture((_) => throw StateError('must not call')),
      Tokens(),
    );
    await expectLater(s.updateNickname(Dio(), 'a'), throwsArgumentError);
  });

  test(
    'concurrent protected 401 clears once while 403 preserves session',
    () async {
      final tokens = Tokens();
      final s = AuthSession(
        fixture(
          (r) => success(
            r.path.endsWith('/login')
                ? {'accessToken': 'test'}
                : {'email': 'a', 'nickname': 'AA'},
          ),
        ),
        tokens,
      );
      await s.login('a', 'b');
      final adapter = StatusAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
        ..httpClientAdapter = adapter;
      dio.interceptors.insert(0, AuthInterceptor(s));
      await expectLater(
        dio.patch('/$workbookVersion/ratings/1'),
        throwsA(isA<DioException>()),
      );
      expect(s.authenticated, true);
      final before = s.generation;
      adapter.code = 'AUTH401_4';
      await Future.wait(
        List.generate(3, (_) async {
          try {
            await dio.get('/$workbookVersion/members/me');
          } on DioException {
            /* expected */
          }
        }),
      );
      expect(s.generation, before + 1);
      expect(s.authenticated, false);
      expect(tokens.value, isNull);
      expect(s.sessionExpired, true);
    },
  );
  test('late rating write response cannot enter next session cache', () async {
    final pending = Completer<Object?>();
    var version = 1;
    final api = RatingApiService(
      fixture((_) => pending.future),
      authenticated: true,
      sessionVersion: () => version,
    );
    final request = api.createRating(
      request: CreateRatingRequest(movieId: 550, score: 4),
    );
    await Future<void>.delayed(Duration.zero);
    version++;
    pending.complete(
      success({
        'ratingId': 1,
        'movieId': 550,
        'score': 4,
        'comment': null,
        'createdAt': '2026-01-01T00:00:00Z',
      }),
    );
    await request;
    expect(await api.fetchMyRatings(0), isEmpty);
  });
  test('storage deletion failure blocks login until cleanup retry', () async {
    final tokens = Tokens();
    final s = AuthSession(
      fixture(
        (r) => success(
          r.path.endsWith('/login')
              ? {'accessToken': 'test'}
              : {'email': 'a', 'nickname': 'AA'},
        ),
      ),
      tokens,
    );
    await s.login('a', 'b');
    tokens.fail = true;
    await expectLater(s.logout(), throwsStateError);
    expect(s.authenticated, false);
    expect(s.cleanupFailed, true);
    await s.login('b', 'b');
    expect(s.authenticated, false);
    tokens.fail = false;
    await s.restore();
    expect(tokens.value, isNull);
    expect(s.cleanupFailed, false);
  });
  test(
    'new login stores token before MainScreen independently loads GET me',
    () async {
      final requests = <String>[];
      final tokens = Tokens();
      final s = AuthSession(
        fixture((r) {
          requests.add(r.path);
          if (r.path.endsWith('/me')) {
            expect(tokens.value, 'test');
            return success({
              'email': 'a',
              'nickname': '검증회원',
              'createdAt': '2026-11-16T00:00:00Z',
            });
          }
          return success({'accessToken': 'test', 'nickname': '로그인회원'});
        }),
        tokens,
      );
      await s.login('a', 'b');
      expect(requests, ['/$workbookVersion/auth/login']);
      expect(s.authenticated, true);
      expect(s.memberStatus, MemberLoadStatus.idle);
      await s.loadMember();
      expect(requests, [
        '/$workbookVersion/auth/login',
        '/$workbookVersion/members/me',
      ]);
      expect(s.nickname, '검증회원');
    },
  );
}
