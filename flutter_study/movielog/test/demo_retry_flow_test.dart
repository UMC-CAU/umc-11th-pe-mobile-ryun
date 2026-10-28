import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/movie/tmdb_movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_list_error.dart';
import 'package:movielog/movie/widgets/movie_list_loading.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';

import 'support/tmdb_test_service.dart';

class _FirstRequestFails extends TestTmdbService {
  bool firstRequest = true;
  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    if (firstRequest) {
      firstRequest = false;
      throw Exception('Test failure');
    }
    return super.fetchGenres();
  }
}

void main() {
  testWidgets('TMDB Route에서 첫 오류 뒤 재시도하면 목록이 표시된다', (tester) async {
    AppRouter.router.go('/movies');
    await tester.pumpWidget(MovieLogApp(movieService: _FirstRequestFails()));
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(MovieListError), findsOneWidget);
    await tester.tap(find.text('다시 시도').last);
    await tester.pumpAndSettle();
    expect(find.byType(TmdbMovieListScreen), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(MovieListError), findsNothing);
  });
}
