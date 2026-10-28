import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/tmdb_logging_interceptor.dart';

void main() {
  for (final header in ['Authorization', 'authorization']) {
    test('masks $header without changing the outgoing token', () async {
      final logs = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        logs.add(message ?? '');
      };
      addTearDown(() => debugPrint = originalDebugPrint);

      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(TmdbLoggingInterceptor());
      String? outgoingToken;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            outgoingToken = options.headers[header] as String?;
            handler.resolve(Response(requestOptions: options, statusCode: 200));
          },
        ),
      );

      await dio.get<dynamic>(
        'https://example.test/movie/popular',
        options: Options(headers: {header: 'Bearer test-secret-token'}),
      );

      expect(outgoingToken, 'Bearer test-secret-token');
      expect(logs.join('\n'), contains('Bearer ***'));
      expect(logs.join('\n'), isNot(contains('test-secret-token')));
    });
  }
}
