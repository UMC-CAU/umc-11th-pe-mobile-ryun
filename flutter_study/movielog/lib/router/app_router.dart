import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../data/services/sign_up_service.dart';
import '../view_models/learning_member_session.dart';
import '../data/services/rating_api_service.dart';
import '../view_models/my_ratings_view_model.dart';

import 'package:provider/provider.dart';

import '../home/home_screen.dart';
import '../main_screen.dart';
import '../movie/movie_detail_loader.dart';
import '../movie/tmdb_movie_list_screen.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
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
    routes: [
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
                    path: 'ratings',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = context
                          .watch<LearningMemberSession>()
                          .memberId;
                      if (id == null) {
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
                        key: ValueKey(id),
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
