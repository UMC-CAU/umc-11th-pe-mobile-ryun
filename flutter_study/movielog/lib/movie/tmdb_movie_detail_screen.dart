import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../widgets/tmdb_poster_image.dart';
import '../widgets/rating_dialog.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../core/session/auth_session.dart';

class TmdbMovieDetailScreen extends StatefulWidget {
  const TmdbMovieDetailScreen({super.key, required this.movie});
  final TmdbMovieDto movie;

  @override
  State<TmdbMovieDetailScreen> createState() => _TmdbMovieDetailScreenState();
}

class _TmdbMovieDetailScreenState extends State<TmdbMovieDetailScreen> {
  Future<void> _openRating() async {
    final model = context.read<MovieDetailViewModel>();
    final session = context.read<AuthSession>();
    final version = session.generation;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          await model.createRating(score: score, comment: comment);
          if (model.submitStatus != SubmitStatus.success) {
            throw StateError(model.submitMessage ?? '저장에 실패했습니다.');
          }
        },
      ),
    );
    if (!mounted || !session.current(version)) return;
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 저장했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final releaseDate = movie.releaseDate;
    final loggedIn = context.watch<AuthSession>().authenticated;
    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: 260,
                height: 390,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(movie.title, style: Theme.of(context).textTheme.headlineSmall),
          if (releaseDate != null && releaseDate.length >= 4)
            Text(releaseDate.substring(0, 4)),
          Text('TMDB 평점: ${movie.voteAverage.toStringAsFixed(1)} / 10'),
          const SizedBox(height: 24),
          Text('시놉시스', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(movie.overview.isEmpty ? '줄거리 정보가 없어요.' : movie.overview),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!loggedIn)
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('평점을 남기려면 로그인해 주세요.'),
              ),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: loggedIn ? _openRating : null,
                    child: const Text('평점 남기기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
