import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_list_error.dart';
import 'package:movielog/movie/widgets/movie_list_loading.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  if (const bool.fromEnvironment('MOVIELOG_DEMO_FAIL_ONCE')) {
    testWidgets('실제 Route에서 첫 오류 뒤 다시 시도하면 영화 목록이 표시된다', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      AppRouter.router.go('/movies');

      await tester.pumpWidget(const MovieLogApp());
      expect(find.byType(MovieListLoading), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(MovieListError), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(find.byType(MovieListLoading), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(MovieGrid), findsOneWidget);
      expect(find.byType(MovieListError), findsNothing);
    });
  }
}
