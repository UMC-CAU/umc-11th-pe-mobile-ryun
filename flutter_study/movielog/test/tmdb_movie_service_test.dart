import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

void main() {
  test(
    'Discover omits genre for all movies and includes a selected ID',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'page': options.queryParameters['page'],
                  'results': [
                    {'id': 550, 'title': '테스트 영화'},
                  ],
                  'total_pages': 2,
                  'total_results': 21,
                },
              ),
            );
          },
        ),
      );
      final service = TmdbMovieService(dio);

      final page = await service.discoverMovies(page: 1);
      await service.discoverMovies(page: 2, genreIds: [28]);
      await service.discoverMovies(page: 1, genreIds: [18, 28]);
      await service.discoverMovies(page: 1, genreIds: []);

      expect(requests.first.path, '/discover/movie');
      expect(
        requests.first.queryParameters.containsKey('with_genres'),
        isFalse,
      );
      expect(requests[1].queryParameters['with_genres'], '28');
      expect(requests[1].queryParameters['page'], 2);
      expect(requests[2].queryParameters['with_genres'], '18|28');
      expect(requests[3].queryParameters.containsKey('with_genres'), isFalse);
      expect(page.results.single.id, 550);
    },
  );

  test(
    'network errors reach the caller for ViewModel error handling',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException.connectionError(
                requestOptions: options,
                reason: 'Test offline',
              ),
            );
          },
        ),
      );

      await expectLater(
        TmdbMovieService(dio).fetchPopular(),
        throwsA(isA<DioException>()),
      );
    },
  );
}
