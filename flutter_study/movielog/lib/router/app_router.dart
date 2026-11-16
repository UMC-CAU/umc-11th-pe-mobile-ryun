import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/session/auth_session.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../home/home_screen.dart';
import '../main_screen.dart';
import '../movie/movie_detail_loader.dart';
import '../movie/tmdb_movie_list_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../profile/my_ratings_screen.dart';
import '../login_screen.dart';
import '../register_screen.dart';
import '../session_splash_screen.dart';
import '../start_screen.dart';

class AppRouter {
  AppRouter._();
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/initializing',
    redirect: (context, state) {
      final session = context.read<AuthSession>();
      final path = state.uri.path;
      if (!session.initialized || session.restoreFailed) {
        return path == '/initializing' ? null : '/initializing';
      }
      if (!session.authenticated && path != '/login' && path != '/register') {
        return '/login';
      }
      if (path == '/initializing' || path == '/start') {
        return session.authenticated ? '/home' : '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/initializing',
        builder: (_, _) => const SessionSplashScreen(),
      ),
      GoRoute(path: '/start', builder: (_, _) => const StartScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, _) =>
            RegisterScreen(memberService: context.read<SignUpService>()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, _) => ChangeNotifierProvider(
                  create: (_) =>
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
                builder: (context, _) => ChangeNotifierProvider(
                  create: (_) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const TmdbMovieListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, state) {
                      final id = int.tryParse(
                        state.pathParameters['movieId'] ?? '',
                      );
                      if (id == null || id < 1) {
                        return Scaffold(
                          appBar: AppBar(),
                          body: const Center(child: Text('영화 ID가 올바르지 않습니다.')),
                        );
                      }
                      final movie = state.extra;
                      return MovieDetailLoader(
                        key: ValueKey(id),
                        movieId: id,
                        initialMovie: movie is TmdbMovieDto && movie.id == id
                            ? movie
                            : null,
                      );
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
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'profile/edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const ProfileEditScreen(),
                  ),
                  GoRoute(
                    path: 'ratings',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, _) {
                      final session = context.watch<AuthSession>();
                      return ChangeNotifierProvider(
                        key: ValueKey('${session.email}:${session.generation}'),
                        create: (_) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                          0,
                        )..load(),
                        child: const MyRatingsScreen(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
