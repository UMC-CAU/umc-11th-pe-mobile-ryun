import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/home/home_screen.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';

import 'support/tmdb_test_service.dart';

void main() {
  for (final count in [0, 2, 8]) {
    testWidgets('home safely renders $count Popular results and rebuilds', (
      tester,
    ) async {
      final service = TestTmdbService()..count = count;
      final vm = MovieHomeViewModel(service);
      addTearDown(vm.dispose);
      Widget subject() => ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(home: HomeScreen(key: UniqueKey())),
      );
      final load = vm.loadPopular();
      await tester.pumpWidget(subject());
      await load;
      await tester.pumpAndSettle();
      if (count == 0) {
        expect(find.text('인기 영화가 없어요.'), findsOneWidget);
      } else {
        await tester.scrollUntilVisible(
          find.text('전체보기'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final section = tester.widget<PopularMoviesSection>(
          find.byType(PopularMoviesSection, skipOffstage: false),
        );
        expect(section.movies.length, count < 5 ? count : 5);
      }
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      expect(service.popularCalls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home retries after an error', (tester) async {
    final service = TestTmdbService()..fail = true;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MovieHomeViewModel(service)..loadPopular(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('인기 영화를 불러오지 못했어요.'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byType(FeaturedMovieCard), findsOneWidget);
    expect(service.popularCalls, 2);
  });
}
