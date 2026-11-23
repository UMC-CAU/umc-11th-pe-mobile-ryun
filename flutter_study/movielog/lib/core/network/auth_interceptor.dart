import 'package:dio/dio.dart';

import '../session/auth_session.dart';
import '../config/study_config.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.session);
  final AuthSession session;
  bool protected(RequestOptions options) {
    final uri = options.uri;
    return uri.scheme == 'https' &&
        uri.host == 'workbook.devnoco.com' &&
        uri.port == 443 &&
        (uri.path == '/$workbookVersion/members/me' ||
            RegExp(
              week8
                  ? r'^/v7/ratings(/|$)'
                  : r'^/v8/(favorites|ratings|movie-records)(/|$)',
            ).hasMatch(uri.path));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.removeWhere(
      (key, _) => key.toLowerCase() == 'authorization',
    );
    if (protected(options)) {
      options.followRedirects = false;
      options.extra['sessionGeneration'] = session.generation;
      final token = session.token;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final version = response.requestOptions.extra['sessionGeneration'];
    if (version is int && !session.current(version)) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.cancel,
          message: '이전 세션 응답',
        ),
      );
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final version = err.requestOptions.extra['sessionGeneration'];
    if (version is int && isSessionExpired(err)) {
      await session.expire(version);
    }
    handler.next(err);
  }
}
