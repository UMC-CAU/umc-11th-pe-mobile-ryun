import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('invalid test token produces a real masked 401 log', () async {
    // Never edit the user's .env or reuse their actual token for this failure.
    const invalidToken = 'intentionally-invalid-test-token';
    dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=$invalidToken');
    final dio = createTmdbClient();
    addTearDown(() => dio.close(force: true));
    final logs = <String>[];
    final originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
    addTearDown(() => debugPrint = originalPrint);
    DioException? failure;
    await HttpOverrides.runWithHttpOverrides(() async {
      try {
        await TmdbMovieService(dio).discoverMovies(page: 1, genreIds: [18, 28]);
      } on DioException catch (error) {
        failure = error;
      }
    }, _RealHttpOverrides());
    expect(failure?.response?.statusCode, 401);
    expect(logs.any((line) => line.contains(invalidToken)), isFalse);
    expect(logs.any((line) => line.startsWith('[TMDB 오류]')), isTrue);
    expect(logs.any((line) => line.startsWith('[TMDB 오류 내용]')), isTrue);
    final safeLogs = logs.join('\n').replaceAll(invalidToken, '***');
    originalPrint(safeLogs);
    if (const bool.fromEnvironment('TMDB_WRITE_EVIDENCE')) {
      final logFile = File('docs/challenge_network_failure_log.txt');
      await logFile.parent.create(recursive: true);
      await logFile.writeAsString(safeLogs);
    }
  }, skip: !const bool.fromEnvironment('TMDB_LIVE_TEST'));
}
