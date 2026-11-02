import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/member_api_service.dart';

void main() {
  test('한글 Path 값을 인코딩하고 available 값을 읽는다', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'available': false},
            ),
          );
        },
      ),
    );
    final service = MemberApiService(dio: dio);
    addTearDown(service.close);
    expect(await service.checkNickname('수현'), isFalse);
    expect(requests.single.uri.pathSegments.last, '수현');
    expect(requests.single.uri.host, 'localhost');
  });

  test('평점 조회는 page와 size를 전달하고 페이지 메타데이터를 읽는다', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    late RequestOptions request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'content': [
                  {
                    'ratingId': 1,
                    'movieId': 550,
                    'score': 5,
                    'comment': null,
                    'createdAt': '2026-10-28T20:00:00',
                  },
                ],
                'page': 1,
                'size': 1,
                'totalElements': 2,
                'totalPages': 2,
                'first': false,
                'last': true,
              },
            ),
          );
        },
      ),
    );
    final service = MemberApiService(dio: dio);
    addTearDown(service.close);
    final page = await service.getRatings(memberId: 1, page: 1, size: 1);
    expect(request.path, '/members/1/ratings');
    expect(request.queryParameters, {'page': 1, 'size': 1});
    expect(page.content.single.movieId, 550);
    expect(page.content.single.comment, isNull);
    expect(page.last, isTrue);
  });

  test('서버의 400 검증 메시지를 화면에 전달한다', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException.badResponse(
              statusCode: 400,
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 400,
                data: {
                  'errors': [
                    {'field': 'email', 'message': '올바른 이메일 형식이 아닙니다.'},
                  ],
                },
              ),
            ),
          );
        },
      ),
    );
    final service = MemberApiService(dio: dio);
    addTearDown(service.close);
    await expectLater(
      service.checkEmail('invalid'),
      throwsA(
        isA<MemberApiException>()
            .having((error) => error.statusCode, 'status', 400)
            .having((error) => error.message, 'message', '올바른 이메일 형식이 아닙니다.'),
      ),
    );
  });
}
