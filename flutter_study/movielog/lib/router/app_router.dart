import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../data/services/sign_up_service.dart';
import '../view_models/learning_member_session.dart';
import '../data/services/rating_api_service.dart';
import '../view_models/my_ratings_view_model.dart';

import 'package:provider/provider.dart';

import '../home/home_screen.dart';
import '../core/config/study_config.dart';
import '../movie/tmdb_movie_list_screen.dart';
import '../view_models/movie_list_view_model.dart';
import '../profile/profile_edit_screen.dart';
import '../session_splash_screen.dart';
import '../main_screen.dart';
import '../movie/movie_detail_loader.dart';
import '../movie/paged_movie_list_screen.dart';
import '../login_screen.dart';
import '../profile/favorites_screen.dart';
import '../core/session/auth_session.dart';
import '../data/services/favorite_api_service.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../profile/profile_screen.dart';
import '../profile/my_ratings_screen.dart';
import '../register_screen.dart';
import '../start_screen.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/start',
    redirect: (context, state) {
      final session = context.read<AuthSession>();
      final path = state.uri.path;
      if (!session.initialized) {
        return path == '/initializing' ? null : '/initializing';
      }
      if (session.restoreFailed) {
        return path == '/initializing' ? null : '/initializing';
      }
      if (week8 &&
          !session.authenticated &&
          path != '/login' &&
          path != '/register') {
        return '/login';
      }
      if (path == '/initializing') {
        return session.authenticated ? '/movies' : '/login';
      }
      if ((path == '/my/favorites' || path == '/my/ratings') &&
          !session.authenticated) {
        return '/login';
      }
      if (session.notice != null &&
          !session.authenticated &&
          path != '/login' &&
          path != '/register' &&
          path != '/start') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/initializing',
        builder: (_, _) => const SessionSplashScreen(),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegisterScreen(memberService: context.read<SignUpService>()),
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
                builder: (context, state) => week8
                    ? ChangeNotifierProvider(
                        create: (context) =>
                            MovieListViewModel(context.read<TmdbMovieService>())
                              ..loadInitial(),
                        child: const TmdbMovieListScreen(),
                      )
                    : ChangeNotifierProvider(
                        create: (context) => PagedMoviesViewModel(
                          context.read<TmdbMovieService>(),
                        )..loadInitial(),
                        child: const PagedMovieListScreen(
                          challenge: bool.fromEnvironment(
                            'WEEK9_CHALLENGE',
                            defaultValue: true,
                          ),
                        ),
                      ),
                routes: [
                  GoRoute(
                    path: 'search',
                    redirect: (_, _) => week8 ? '/movies' : null,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, _) => ChangeNotifierProvider(
                      create: (_) => PagedMoviesViewModel(
                        context.read<TmdbMovieService>(),
                        searchMode: true,
                      ),
                      child: const PagedMovieListScreen(
                        search: true,
                        challenge: bool.fromEnvironment(
                          'WEEK9_CHALLENGE',
                          defaultValue: true,
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':movieId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final movieId = int.tryParse(
                        state.pathParameters['movieId'] ?? '',
                      );
                      final movie = state.extra;
                      if (movieId == null || movieId < 1) {
                        return Scaffold(
                          appBar: AppBar(),
                          body: const Center(child: Text('영화 ID가 올바르지 않습니다.')),
                        );
                      }
                      return MovieDetailLoader(
                        key: ValueKey(movieId),
                        movieId: movieId,
                        initialMovie:
                            movie is TmdbMovieDto && movie.id == movieId
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
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'profile/edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const ProfileEditScreen(),
                  ),
                  GoRoute(
                    path: 'favorites',
                    redirect: (_, _) => week8 ? '/my' : null,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, _) {
                      final session = context.watch<AuthSession>();
                      return ChangeNotifierProvider(
                        key: ValueKey('${session.email}:${session.generation}'),
                        create: (_) => FavoritesViewModel(
                          context.read<FavoriteApi>(),
                          context.read<TmdbMovieService>(),
                          session,
                        )..refresh(),
                        child: const FavoritesScreen(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'ratings',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final session = context.watch<AuthSession>();
                      final id =
                          context.watch<LearningMemberSession>().memberId ?? 0;
                      if (!session.authenticated) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('내가 등록한 평점')),
                          body: Center(
                            child: TextButton(
                              onPressed: () => context.push('/register'),
                              child: const Text('학습용 회원가입이 필요합니다.'),
                            ),
                          ),
                        );
                      }
                      return ChangeNotifierProvider(
                        key: ValueKey('${session.email}:${session.generation}'),
                        create: (context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                          id,
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
