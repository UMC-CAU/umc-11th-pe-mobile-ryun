import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:movielog/core/session/auth_session.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/movie/paged_movie_list_screen.dart';

import 'week9_test.dart' show MemoryTokens;

import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';

import 'support/tmdb_test_service.dart';

class _FirstRequestFails extends TestTmdbService {
  bool firstRequest = true;
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    if (firstRequest) {
      firstRequest = false;
      throw Exception('Test failure');
    }
    return super.discoverMovies(page: page, genreIds: genreIds);
  }
}

void main() {
  testWidgets('TMDB Route에서 첫 오류 뒤 재시도하면 목록이 표시된다', (tester) async {
    AppRouter.router.go('/movies');
    final session = AuthSession(Dio(), MemoryTokens())..initialized = true;
    await tester.pumpWidget(
      MovieLogApp(movieService: _FirstRequestFails(), authSession: session),
    );
    await tester.pumpAndSettle();
    if (AppRouter.router.routerDelegate.currentConfiguration.error
        case final error?) {
      debugPrint('Route error: $error');
    }
    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);
    await tester.tap(find.text('다시 시도').last);
    await tester.pumpAndSettle();
    expect(find.byType(PagedMovieListScreen), findsOneWidget);
    expect(find.byType(SliverList), findsOneWidget);
    expect(find.text('영화를 불러오지 못했습니다.'), findsNothing);
  });
}
