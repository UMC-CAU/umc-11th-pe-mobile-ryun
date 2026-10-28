import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'core/network/tmdb_client.dart';
import 'data/services/tmdb_movie_service.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key, this.movieService});

  final TmdbMovieService? movieService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
