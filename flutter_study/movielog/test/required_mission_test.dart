import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/common/movie_rating_input.dart';
import 'package:movielog/home/home_screen.dart';
import 'package:movielog/movie/movie_detail_screen.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_card.dart';
import 'package:movielog/movielog_app.dart';
import 'package:movielog/profile/profile_screen.dart';
import 'package:movielog/register_screen.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  testWidgets('최종 챌린지 사용자 흐름이 동작한다', (tester) async {
    AppRouter.router.go('/home');
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('상세보기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('상세보기'));
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('4.5'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final indicator = tester.widget<RatingBarIndicator>(
      find.byType(RatingBarIndicator),
    );
    expect(indicator.rating, 4.5);

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieRatingInput), findsOneWidget);
    expect(find.byKey(const Key('resetRatingButton')), findsNothing);

    final ratingStars = find.descendant(
      of: find.byType(MovieRatingInput),
      matching: find.byIcon(Icons.star),
    );
    await tester.tap(ratingStars.at(3));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('다시 선택하기'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 선택하기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resetRatingButton')), findsOneWidget);
    await tester.tap(find.byKey(const Key('resetRatingButton')));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('별점을 초기화했습니다.'), findsOneWidget);
    expect(find.text('평점 남기기'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('즐겨찾기'));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
    expect(find.text('즐겨찾기 해제'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.movie_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListScreen), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.filter_list), findsOneWidget);

    await tester.tap(find.byKey(const Key('genreFilterButton')));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);

    tester
        .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, '드라마'))
        .onChanged
        ?.call(true);
    tester
        .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'SF'))
        .onChanged
        ?.call(true);
    await tester.pump();
    expect(
      AppRouter
          .router
          .routeInformationProvider
          .value
          .uri
          .queryParametersAll['genre'],
      isNull,
    );

    tester
        .widget<ElevatedButton>(find.byKey(const Key('applyGenreFilterButton')))
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    final selectedGenres = AppRouter
        .router
        .routeInformationProvider
        .value
        .uri
        .queryParametersAll['genre'];
    expect(selectedGenres, containsAll(['드라마', 'SF']));
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies,
      hasLength(3),
    );

    await tester.tap(find.byType(MovieCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.movie_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListScreen), findsOneWidget);
    expect(
      AppRouter
          .router
          .routeInformationProvider
          .value
          .uri
          .queryParametersAll['genre'],
      containsAll(['드라마', 'SF']),
    );

    await tester.tap(find.byKey(const Key('genreFilterButton')));
    await tester.pumpAndSettle();
    tester
        .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, '드라마'))
        .onChanged
        ?.call(false);
    tester
        .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'SF'))
        .onChanged
        ?.call(false);
    tester
        .widget<ElevatedButton>(find.byKey(const Key('applyGenreFilterButton')))
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    expect(
      AppRouter
          .router
          .routeInformationProvider
          .value
          .uri
          .queryParametersAll['genre'],
      isNull,
    );
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies,
      hasLength(6),
    );

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('회원가입 화면에서는 뒤로 갈 수 없다', (tester) async {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
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
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
