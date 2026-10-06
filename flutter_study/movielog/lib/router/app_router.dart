import 'package:go_router/go_router.dart';

import '../home/home_screen.dart';
import '../main_screen.dart';
import '../movie/movie_detail_screen.dart';
import '../movie/movie_list_screen.dart';
import '../profile/profile_screen.dart';
import '../register_screen.dart';
import '../services/fake_movie_service.dart';
import '../start_screen.dart';

class AppRouter {
  AppRouter._();

  // flutter run --dart-define=MOVIELOG_DEMO_FAIL_ONCE=true
  // 같은 서비스 인스턴스를 유지하여 첫 실패 후 '다시 시도'는 성공하게 한다.
  static final FakeMovieService _movieService =
      const bool.fromEnvironment('MOVIELOG_DEMO_FAIL_ONCE')
      ? FirstAttemptFailsMovieService()
      : const FakeMovieService();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => MovieListScreen(
                  movieService: _movieService,
                  selectedGenres: state.uri.queryParametersAll['genre'],
                ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) {
                      final movieId = int.tryParse(
                        state.pathParameters['movieId'] ?? '',
                      );
                      return MovieDetailScreen(movieId: movieId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
