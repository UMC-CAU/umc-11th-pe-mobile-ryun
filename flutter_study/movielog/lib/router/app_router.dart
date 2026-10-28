import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../home/home_screen.dart';
import '../main_screen.dart';
import '../movie/movie_detail_screen.dart';
import '../movie/tmdb_movie_list_screen.dart';
import '../movie/tmdb_movie_detail_screen.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
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
                builder: (context, state) => ChangeNotifierProvider(
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const TmdbMovieListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) {
                      final movieId = int.tryParse(
                        state.pathParameters['movieId'] ?? '',
                      );
                      final movie = state.extra;
                      if (movie is TmdbMovieDto && movie.id == movieId) {
                        return TmdbMovieDetailScreen(movie: movie);
                      }
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
