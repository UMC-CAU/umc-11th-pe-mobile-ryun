import 'package:dio/dio.dart';
import 'package:movielog/core/session/auth_session.dart';

class _MemoryTokens implements TokenStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? token) async {
    value = token;
  }
}

Future<AuthSession> signedInTestSession() async {
  final client = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'isSuccess': true,
                'code': 'COMMON200',
                'message': '테스트 응답',
                'result': options.path.endsWith('/login')
                    ? {'accessToken': 'fixture-token', 'nickname': '테스트'}
                    : {
                        'email': 'fixture@example.invalid',
                        'nickname': '테스트',
                        'createdAt': '2026-11-16T00:00:00Z',
                      },
              },
            ),
          );
        },
      ),
    );
  final session = AuthSession(client, _MemoryTokens());
  await session.login('fixture@example.invalid', 'fixture-password');
  return session;
}
