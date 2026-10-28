import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../widgets/tmdb_poster_image.dart';
import 'movie_detail_screen.dart';

// 목록에서 받은 DTO를 사용한다. 별도의 상세 API는 이번 실습 범위 밖이다.
class TmdbMovieDetailScreen extends StatefulWidget {
  const TmdbMovieDetailScreen({super.key, required this.movie});
  final TmdbMovieDto movie;

  @override
  State<TmdbMovieDetailScreen> createState() => _TmdbMovieDetailScreenState();
}

class _TmdbMovieDetailScreenState extends State<TmdbMovieDetailScreen> {
  double? _rating;
  bool _favorite = false;

  Future<void> _openRating() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (_) => RatingDialog(
        movieId: widget.movie.id,
        initialRating: _rating ?? 3.5,
        canReset: _rating != null,
      ),
    );
    if (!mounted || rating == null) return;
    setState(() => _rating = rating == 0 ? null : rating);
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final releaseDate = movie.releaseDate;
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
          if (_rating != null) Text('내 별점: ${_rating!.toStringAsFixed(1)}점'),
          const SizedBox(height: 24),
          Text('시놉시스', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(movie.overview.isEmpty ? '줄거리 정보가 없어요.' : movie.overview),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _favorite = !_favorite),
                child: Text(_favorite ? '즐겨찾기 해제' : '즐겨찾기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _openRating,
                child: Text(_rating == null ? '평점 남기기' : '다시 선택하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
