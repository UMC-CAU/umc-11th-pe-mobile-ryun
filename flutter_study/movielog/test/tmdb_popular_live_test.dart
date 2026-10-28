import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';

class _ObservedService extends TmdbMovieService {
  _ObservedService(super.dio);
  TmdbMoviePageDto? receivedPage;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    return receivedPage = await super.fetchPopular(page: page);
  }
}

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('real Popular response, masked logs, DTO, and top five', () async {
    await dotenv.load(fileName: '.env');
    final token = TmdbConfig.accessToken;
    expect(token.isNotEmpty, isTrue, reason: 'Local TMDB token is required');

    final logs = <String>[];
    final originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      logs.add(message ?? '');
    };
    addTearDown(() => debugPrint = originalPrint);
    final dio = createTmdbClient();
    addTearDown(() => dio.close(force: true));
    int? statusCode;
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          statusCode = response.statusCode;
          handler.next(response);
        },
      ),
    );
    final service = _ObservedService(dio);
    final vm = MovieHomeViewModel(service);
    addTearDown(vm.dispose);
    // Widget-test networking is replaced by a fake client by default.
    // Only this explicitly enabled live test uses a real HttpClient.
    await HttpOverrides.runWithHttpOverrides(
      () => vm.loadPopular(),
      _RealHttpOverrides(),
    );

    final tokenWasLogged = logs.any((line) => line.contains(token));
    expect(tokenWasLogged, isFalse, reason: 'Raw token must never be logged');
    for (final line in logs.where(
      (line) =>
          line.startsWith('[TMDB 요청]') ||
          line.startsWith('[TMDB 요청 Header]') ||
          line.startsWith('[TMDB 응답]') ||
          line.startsWith('[TMDB 오류'),
    )) {
      originalPrint(line.replaceAll(token, '***'));
    }
    expect(statusCode, 200);
    expect(logs.any((line) => line.contains('Bearer ***')), isTrue);
    final page = service.receivedPage!;
    expect(
      vm.popularMovies.map((movie) => movie.id),
      page.results.take(5).map((movie) => movie.id),
    );
    expect(
      vm.status,
      page.results.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success,
    );
    originalPrint(
      '[Guided Practice] DTO page=${page.page}, '
      'results=${page.results.length}, selected=${vm.popularMovies.length}',
    );
  }, skip: !const bool.fromEnvironment('TMDB_LIVE_TEST'));
}
