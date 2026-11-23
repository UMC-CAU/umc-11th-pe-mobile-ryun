import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../widgets/tmdb_poster_image.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/week8_ui.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../core/session/auth_session.dart';
import '../core/config/study_config.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/models/favorite_models.dart';
import '../data/models/rating_request.dart';

class TmdbMovieDetailScreen extends StatefulWidget {
  const TmdbMovieDetailScreen({super.key, required this.movie});
  final TmdbMovieDto movie;

  @override
  State<TmdbMovieDetailScreen> createState() => _TmdbMovieDetailScreenState();
}

class _TmdbMovieDetailScreenState extends State<TmdbMovieDetailScreen> {
  Future<void> _openRating() async {
    final model = context.read<MovieDetailViewModel>();
    final favorites = context.read<FavoriteDetailViewModel>();
    final api = context.read<FavoriteApi>();
    final ratings = context.read<RatingApiService>();
    final session = context.read<AuthSession>();
    final version = session.generation;
    const challenge =
        !week8 && bool.fromEnvironment('WEEK9_CHALLENGE', defaultValue: true);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        showAddToFavorite:
            challenge && favorites.known && !favorites.isFavorite,
        onSubmitWithFavorite: challenge
            ? (score, comment, addToFavorites) async {
                if (!session.current(version)) throw StateError('세션이 변경되었습니다.');
                if (!favorites.known) throw StateError('즐겨찾기 여부를 먼저 확인해 주세요.');
                if (!favorites.isFavorite) {
                  final result = await api.saveRecord(
                    CreateMovieRecordRequest(
                      movieId: widget.movie.id,
                      score: score,
                      comment: comment,
                      addToFavorites: addToFavorites,
                    ),
                  );
                  if (session.current(version)) {
                    ratings.rememberRating(result.rating);
                  }
                } else {
                  await ratings.createRating(
                    memberId: 0,
                    request: CreateRatingRequest(
                      movieId: widget.movie.id,
                      score: score,
                      comment: comment,
                    ),
                  );
                }
              }
            : null,
        onSubmit: (score, comment) async {
          await model.createRating(score: score, comment: comment);
          if (model.submitStatus != SubmitStatus.success) {
            throw StateError(model.submitMessage ?? '저장에 실패했습니다.');
          }
        },
      ),
    );
    if (!mounted || !session.current(version)) return;
    if (!week8) await favorites.load();
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 저장했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final releaseDate = movie.releaseDate;
    final loggedIn = context.watch<AuthSession>().authenticated;
    final favorite = context.watch<FavoriteDetailViewModel>();
    return Scaffold(
      appBar: Week8Ui.appBar('영화 상세', onBack: () => context.pop()),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  movie.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (!week8 && favorite.busy)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(),
                )
              else if (!week8)
                IconButton(
                  key: const Key('favoriteButton'),
                  tooltip: favorite.known ? '즐겨찾기' : '즐겨찾기 다시 확인',
                  icon: Icon(
                    favorite.isFavorite
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                  onPressed: !loggedIn
                      ? () => context.push('/login')
                      : () async {
                          await favorite.toggle();
                          if (!context.mounted || !favorite.alive) return;
                          if (favorite.message case final String message) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(message)));
                          }
                        },
                ),
            ],
          ),
          if (!week8 && favorite.message != null) Text(favorite.message!),
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
                    onPressed:
                        !loggedIn ||
                            (!week8 && (favorite.busy || !favorite.known))
                        ? null
                        : _openRating,
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
