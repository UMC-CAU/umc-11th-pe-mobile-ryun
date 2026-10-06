import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/genre_preference.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_list_empty.dart';
import 'package:movielog/movie/widgets/movie_list_error.dart';
import 'package:movielog/movie/widgets/movie_list_loading.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

class _CountingMovieService extends FakeMovieService {
  _CountingMovieService({this.failFirst = false});

  final bool failFirst;
  int calls = 0;

  @override
  Future<List<Movie>> fetchMovies() async {
    calls++;
    if (failFirst && calls == 1) {
      await Future<void>.delayed(const Duration(seconds: 1));
      throw StateError('internal_secret_stack_details');
    }
    return super.fetchMovies();
  }
}

final class _FailingPreferences extends InMemorySharedPreferencesAsync {
  _FailingPreferences() : super.empty();

  bool failRead = false;
  bool failWrite = false;

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) async {
    if (failRead) throw StateError('internal_read_error');
    return super.getStringList(key, options);
  }

  @override
  Future<bool> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async {
    if (failWrite) throw StateError('internal_write_error');
    return super.setStringList(key, value, options);
  }
}

GoRouter _router({
  FakeMovieService service = const FakeMovieService(),
  String initialLocation = '/movies',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/movies',
        builder: (context, state) => MovieListScreen(
          movieService: service,
          selectedGenres: state.uri.queryParametersAll['genre'],
        ),
      ),
      GoRoute(
        path: '/other',
        builder: (context, state) => const Scaffold(body: Text('다른 화면')),
      ),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

Finder _chip(String genre) => find.widgetWithText(FilterChip, genre);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('800ms 이상 로딩 후 기존 Grid를 표시하고 필터·재빌드는 재요청하지 않는다', (tester) async {
    final service = _CountingMovieService();
    final router = _router(service: service);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(MovieListLoading), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);
    await tester.pump(const Duration(milliseconds: 199));
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies,
      hasLength(6),
    );

    await tester.tap(_chip('드라마'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies,
      hasLength(2),
    );
    expect(await GenrePreference().read(), ['드라마']);

    await tester.tap(_chip('SF'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListEmpty), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);
    expect(find.byType(MovieListError), findsNothing);

    await tester.pumpWidget(
      MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(service.calls, 1);
    expect(find.byType(MovieListLoading), findsNothing);

    // Empty에서도 선택을 해제하면 재요청 없이 영화 목록으로 돌아온다.
    await tester.tap(_chip('SF'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MovieGrid>(find.byType(MovieGrid))
          .movies
          .map((movie) => movie.id),
      [1, 4],
    );
    expect(service.calls, 1);
  });

  testWidgets('주·보조 장르를 함께 확인하고 선택한 모든 장르를 만족해야 표시한다', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.ensureVisible(_chip('로맨스'));
    await tester.tap(_chip('로맨스'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MovieGrid>(find.byType(MovieGrid))
          .movies
          .map((movie) => movie.id),
      [1, 4],
    );
    await tester.ensureVisible(_chip('드라마'));
    await tester.tap(_chip('드라마'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MovieGrid>(find.byType(MovieGrid))
          .movies
          .map((movie) => movie.id),
      [1, 4],
    );

    await tester.tap(_chip('SF'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListEmpty), findsOneWidget);
    await tester.tap(_chip('전체'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies,
      hasLength(6),
    );
  });

  testWidgets('빈 응답을 Empty로 표시한다', (tester) async {
    final router = _router(
      service: const FakeMovieService(mode: MovieLoadMode.empty),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListEmpty), findsOneWidget);
    expect(find.byType(MovieListError), findsNothing);
    expect(find.byType(MovieGrid), findsNothing);
  });

  testWidgets('실패 모드에서 안전한 오류 문구와 다시 시도 버튼을 표시한다', (tester) async {
    final router = _router(
      service: const FakeMovieService(mode: MovieLoadMode.failure),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('오류는 자동 재요청하지 않고 버튼으로 Loading → Success 전환한다', (tester) async {
    final service = _CountingMovieService(failFirst: true);
    final router = _router(service: service);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.textContaining('internal_secret'), findsNothing);

    await tester.pumpWidget(
      MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(service.calls, 1);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(service.calls, 2);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('새 화면과 새 저장 객체에서도 마지막 장르 및 전체 선택을 복원한다', (tester) async {
    var router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(_chip('드라마'));
    await tester.pumpAndSettle();
    await tester.tap(_chip('SF'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(_chip('드라마')).selected, isTrue);
    expect(tester.widget<FilterChip>(_chip('SF')).selected, isTrue);
    expect(find.byType(MovieListEmpty), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);

    await tester.tap(_chip('전체'));
    await tester.pumpAndSettle();
    expect(await GenrePreference().read(), isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(_chip('전체')).selected, isTrue);
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies,
      hasLength(6),
    );
  });

  testWidgets('주소의 장르가 저장값보다 우선하고 필터 결과가 없으면 해제할 수 있다', (tester) async {
    await GenrePreference().save(['드라마']);
    final service = _CountingMovieService();
    final router = _router(
      service: service,
      initialLocation: '/movies?genre=SF',
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(_chip('SF')).selected, isTrue);
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies,
      hasLength(1),
    );

    router.go(
      Uri(path: '/movies', queryParameters: {'genre': '없는 장르'}).toString(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MovieListEmpty), findsOneWidget);
    await tester.tap(_chip('전체'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieGrid), findsOneWidget);
    expect(service.calls, 1);
  });

  testWidgets('저장 읽기 실패를 재시도할 수 있고 쓰기 실패 후에도 다음 선택을 저장한다', (tester) async {
    final store = _FailingPreferences()..failRead = true;
    SharedPreferencesAsyncPlatform.instance = store;
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(MovieListError), findsOneWidget);

    store.failRead = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieGrid), findsOneWidget);

    store.failWrite = true;
    await tester.tap(_chip('드라마'));
    await tester.pumpAndSettle();
    expect(find.text('장르를 저장하지 못했습니다. 다시 선택해 주세요.'), findsOneWidget);
    expect(find.textContaining('internal_write'), findsNothing);
    store.failWrite = false;
    await tester.tap(_chip('SF'));
    await tester.pumpAndSettle();
    expect(await GenrePreference().read(), ['드라마', 'SF']);
  });

  testWidgets('로딩 중 화면을 벗어나도 dispose 이후 화면을 갱신하지 않는다', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/other');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('다른 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('연속 저장은 마지막 선택을 남긴다', () async {
    final preference = GenrePreference();
    await Future.wait([
      preference.save(['드라마']),
      preference.save(['드라마', 'SF']),
      preference.save([]),
    ]);
    expect(await GenrePreference().read(), isEmpty);
  });
}
