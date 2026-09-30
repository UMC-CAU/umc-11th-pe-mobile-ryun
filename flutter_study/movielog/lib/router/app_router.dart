import 'package:go_router/go_router.dart';

import '../home/home_screen.dart';
import '../main_screen.dart';
import '../movie/movie_detail_screen.dart';
import '../movie/movie_list_screen.dart';
import '../profile/profile_screen.dart';
import '../register_screen.dart';
import '../start_screen.dart';

class AppRouter {
  AppRouter._();

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
                  selectedGenres: state.uri.queryParametersAll['genre'] ?? [],
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
