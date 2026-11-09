import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/home/home_screen.dart';
import 'package:movielog/movie/tmdb_movie_detail_screen.dart';
import 'package:movielog/movie/tmdb_movie_list_screen.dart';
import 'package:movielog/movie/widgets/tmdb_movie_card.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/register_screen.dart';
import 'package:movielog/router/app_router.dart';

import 'support/tmdb_test_service.dart';

void main() {
  testWidgets('TMDB 홈, 장르 목록, 상세 연결, 가입 전 평점 제한 및 탭 상태 유지', (tester) async {
    final service = TestTmdbService();
    AppRouter.router.go('/home');
    await tester.pumpWidget(MovieLogApp(movieService: service));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(service.popularCalls, 1);

    await tester.scrollUntilVisible(
      find.text('전체보기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(TmdbMovieCard), findsWidgets);
    await tester.tap(find.text('전체보기'));
    await tester.pumpAndSettle();
    expect(find.byType(TmdbMovieListScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, '액션'));
    await tester.pumpAndSettle();
    expect(service.requests.last.genreIds, [28]);
    await tester.tap(find.byType(TmdbMovieCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(TmdbMovieDetailScreen), findsOneWidget);
    final rateButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '평점 남기기'),
    );
    expect(rateButton.onPressed, isNull);
    expect(find.text('평점을 남기려면 학습용 회원가입을 완료해 주세요.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '전체'));
    await tester.pumpAndSettle();
    expect(service.requests.last.genreIds, isNull);
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(service.popularCalls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('제출 전 회원가입 화면은 앱바 뒤로가기를 제공한다', (tester) async {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => const Scaffold(body: Text('시작 화면')),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('홈')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('시작 화면'), findsOneWidget);
  });
}
