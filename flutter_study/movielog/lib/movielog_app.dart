import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'core/network/tmdb_client.dart';
import 'core/config/study_config.dart';
import 'core/network/movie_log_client.dart';
import 'core/network/auth_interceptor.dart';
import 'core/session/auth_session.dart';
import 'data/services/member_check_service.dart';
import 'data/services/sign_up_service.dart';
import 'view_models/learning_member_session.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/tmdb_movie_service.dart';

import 'router/app_router.dart';
import 'profile/profile_edit_screen.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.movieService,
    this.memberCheckService,
    this.ratingApiService,
    this.signUpService,
    this.authSession,
    this.profileClient,
  });

  final TmdbMovieService? movieService;
  final MemberCheckService? memberCheckService;
  final RatingApiService? ratingApiService;
  final SignUpService? signUpService;
  final AuthSession? authSession;
  final Dio? profileClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LearningMemberSession()),
        Provider<_PublicClient>(
          create: (_) => _PublicClient(createMovieLogClient()),
          dispose: (_, client) => client.dio.close(force: true),
        ),
        ChangeNotifierProvider<AuthSession>(
          create: (context) =>
              authSession ??
              (AuthSession(
                context.read<_PublicClient>().dio,
                SecureTokenStorage(),
              )..restore()),
        ),
        Provider<_WorkbookClient>(
          create: (context) => _WorkbookClient(
            createMovieLogClient()
              ..interceptors.add(AuthInterceptor(context.read<AuthSession>())),
          ),
          dispose: (_, client) => client.dio.close(force: true),
        ),
        Provider<ProfileAuthClient>(
          create: (context) => ProfileAuthClient(
            profileClient ?? context.read<_WorkbookClient>().dio,
          ),
        ),
        Provider<SignUpService>(
          create: (context) =>
              signUpService ??
              memberCheckService ??
              SignUpService(
                context.read<_PublicClient>().dio,
                version: workbookVersion,
              ),
        ),
        Provider<RatingApiService>(
          create: (context) =>
              ratingApiService ??
              RatingApiService(
                context.read<_WorkbookClient>().dio,
                authenticated: true,
                publicClient: context.read<_PublicClient>().dio,
                sessionVersion: () => context.read<AuthSession>().generation,
              ),
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
      child: const _SessionRouter(),
    );
  }
}

class _SessionRouter extends StatefulWidget {
  const _SessionRouter();
  @override
  State<_SessionRouter> createState() => _SessionRouterState();
}

class _SessionRouterState extends State<_SessionRouter> {
  AuthSession? _session;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<AuthSession>();
    if (!identical(session, _session)) {
      _session?.removeListener(_refresh);
      _session = session;
      session.addListener(_refresh);
    }
  }

  void _refresh() => AppRouter.router.refresh();
  @override
  void dispose() {
    _session?.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'MovieLog',
    theme: AppTheme.light,
    routerConfig: AppRouter.router,
  );
}

class _WorkbookClient {
  _WorkbookClient(this.dio);
  final Dio dio;
}

class _PublicClient {
  _PublicClient(this.dio);
  final Dio dio;
}
