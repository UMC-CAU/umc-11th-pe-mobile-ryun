import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'core/network/tmdb_client.dart';
import 'core/network/movie_log_client.dart';
import 'data/services/member_check_service.dart';
import 'data/services/sign_up_service.dart';
import 'view_models/learning_member_session.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/tmdb_movie_service.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.movieService,
    this.memberCheckService,
    this.ratingApiService,
    this.signUpService,
  });

  final TmdbMovieService? movieService;
  final MemberCheckService? memberCheckService;
  final RatingApiService? ratingApiService;
  final SignUpService? signUpService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LearningMemberSession()),
        Provider<_WorkbookClient>(
          create: (_) => _WorkbookClient(createMovieLogClient()),
          dispose: (_, client) => client.dio.close(force: true),
        ),
        Provider<SignUpService>(
          create: (context) =>
              signUpService ??
              memberCheckService ??
              SignUpService(context.read<_WorkbookClient>().dio),
        ),
        Provider<RatingApiService>(
          create: (context) =>
              ratingApiService ??
              RatingApiService(context.read<_WorkbookClient>().dio),
        ),
        Provider<Dio>(
          create: (_) => createTmdbClient(),
          dispose: (_, dio) => dio.close(force: true),
        ),
        Provider<TmdbMovieService>(
          create: (context) =>
              movieService ?? TmdbMovieService(context.read<Dio>()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

class _WorkbookClient {
  _WorkbookClient(this.dio);
  final Dio dio;
}
