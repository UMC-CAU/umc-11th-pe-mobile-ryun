import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/services/rating_api_service.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import 'tmdb_movie_detail_screen.dart';

class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });
  final int movieId;
  final TmdbMovieDto? initialMovie;
  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late Future<TmdbMovieDto> _future = _fetch();
  Future<TmdbMovieDto> _fetch() => widget.initialMovie != null
      ? Future.value(widget.initialMovie!)
      : context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  @override
  Widget build(BuildContext context) => FutureBuilder<TmdbMovieDto>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('영화 상세')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('영화 정보를 불러오지 못했습니다.'),
                TextButton(
                  onPressed: () => setState(() => _future = _fetch()),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        );
      }
      final movie = snapshot.data;
      if (movie == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final memberId = context.watch<LearningMemberSession>().memberId;
      return ChangeNotifierProvider(
        key: ValueKey('${movie.id}:$memberId'),
        create: (context) => MovieDetailViewModel(
          context.read<RatingApiService>(),
          memberId,
          movie,
        ),
        child: TmdbMovieDetailScreen(movie: movie),
      );
    },
  );
}
