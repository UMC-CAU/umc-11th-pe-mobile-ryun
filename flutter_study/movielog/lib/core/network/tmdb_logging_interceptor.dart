import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      // 로그용 복사본만 수정하여 실제 인증 헤더는 유지한다.
      final maskedHeaders = Map<String, dynamic>.from(options.headers);
      for (final key in maskedHeaders.keys.toList()) {
        if (key.toLowerCase() == 'authorization') {
          maskedHeaders[key] = 'Bearer ***';
        }
      }
      debugPrint('[TMDB 요청] ${options.method} ${options.uri}');
      debugPrint('[TMDB 요청 Header] $maskedHeaders');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('[TMDB 요청 Query] ${options.queryParameters}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[TMDB 응답] ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('[TMDB 응답 Body] ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[TMDB 오류] ${err.requestOptions.uri}');
      debugPrint('[TMDB 오류 Status] ${err.response?.statusCode}');
      debugPrint('[TMDB 오류 내용] ${err.message}');
    }
    handler.next(err);
  }
}
