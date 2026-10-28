import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/tmdb_logging_interceptor.dart';

void main() {
  test('logging registration and all hooks respect build mode', () async {
    dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=test-mode-token');
    final dio = createTmdbClient();
    addTearDown(() => dio.close(force: true));
    expect(
      dio.interceptors.whereType<TmdbLoggingInterceptor>().length,
      kDebugMode ? 1 : 0,
    );
    // Also verify the interceptor itself is silent if registered manually.
    dio.interceptors.clear();
    dio.interceptors.add(TmdbLoggingInterceptor());
    final logs = <String>[];
    final originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
    addTearDown(() => debugPrint = originalPrint);
    var fail = false;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (fail) {
            handler.reject(
              DioException(requestOptions: options, message: 'Test failure'),
            );
          } else {
            handler.resolve(Response(requestOptions: options, statusCode: 200));
          }
        },
      ),
    );
    await dio.get<dynamic>('/discover/movie');
    fail = true;
    await expectLater(
      dio.get<dynamic>('/discover/movie'),
      throwsA(isA<DioException>()),
    );
    expect(logs.any((line) => line.contains('test-mode-token')), isFalse);
    if (kDebugMode) {
      expect(logs, isNotEmpty);
    } else {
      expect(logs, isEmpty);
    }
    originalPrint(
      '[Logging check] kDebugMode=$kDebugMode, kReleaseMode=$kReleaseMode, logLines=${logs.length}',
    );
  });
}
