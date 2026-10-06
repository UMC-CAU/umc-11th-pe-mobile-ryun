import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../common/movie_rating_input.dart';
import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final int? movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  static const _feedbackDuration = Duration(milliseconds: 1500);

  bool _isFavorite = false;
  double? _myRating;

  Future<void> _openRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        initialRating: _myRating ?? 3.5,
        canReset: _myRating != null,
      ),
    );

    if (!mounted || rating == null) return;

    if (rating == 0) {
      setState(() => _myRating = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('별점을 초기화했습니다.'),
          behavior: SnackBarBehavior.floating,
          duration: _feedbackDuration,
        ),
      );
      return;
    }

    setState(() => _myRating = rating);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('별점 ${rating.toStringAsFixed(1)}점을 기록했습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: _feedbackDuration,
      ),
    );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        behavior: SnackBarBehavior.floating,
        duration: _feedbackDuration,
      ),
    );
  }

  void _shareMovie() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('공유 기능은 준비 중입니다.'),
        behavior: SnackBarBehavior.floating,
        duration: _feedbackDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(widget.movieId);
    if (movie == null) return const _MovieNotFound();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(movie.title),
        actions: [
          IconButton(
            tooltip: '공유',
            onPressed: _shareMovie,
            icon: const Icon(Icons.share_outlined, color: AppColors.iconGray),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Center(child: _Poster(movie: movie)),
          const SizedBox(height: 24),
          Text(movie.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '${movie.year} · ${movie.genre}/${movie.secondaryGenre} · '
            '${movie.durationMinutes}분',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              RatingBarIndicator(
                rating: movie.averageRating,
                itemCount: 5,
                itemSize: 24,
                itemBuilder: (context, index) =>
                    const Icon(Icons.star, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(movie.averageRating.toStringAsFixed(1)),
              const SizedBox(width: 6),
              Text(
                '(${_formatReviewCount(movie.reviewCount)})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MovieTag(label: movie.genre),
              _MovieTag(label: movie.secondaryGenre),
              for (final mood in movie.moods) _MovieTag(label: mood),
            ],
          ),
          if (_myRating != null) ...[
            const SizedBox(height: 12),
            Text('내 별점: ${_myRating!.toStringAsFixed(1)}점'),
          ],
          const SizedBox(height: 32),
          Text('시놉시스', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            '서로의 존재를 잊고 살아가던 두 사람이 우연한 계기로 다시 만나, '
            '잊고 있던 꿈과 사랑을 되찾아가는 따뜻한 이야기입니다.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                ),
                label: Text(_isFavorite ? '즐겨찾기 해제' : '즐겨찾기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _openRatingDialog,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(_myRating == null ? '평점 남기기' : '다시 선택하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _MovieTag extends StatelessWidget {
  const _MovieTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E7E5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.bodyText, fontSize: 12),
      ),
    );
  }
}

String _formatReviewCount(int count) {
  if (count < 1000) return count.toString();
  final thousands = count ~/ 1000;
  final remainder = (count % 1000).toString().padLeft(3, '0');
  return '$thousands,$remainder';
}

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    required this.initialRating,
    required this.canReset,
  });

  final double initialRating;
  final bool canReset;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double rating = widget.initialRating;
  late bool _showResetAction = widget.canReset;

  void _resetRating() {
    setState(() {
      rating = 0;
      _showResetAction = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '영화는 어떠셨나요?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 32),
            MovieRatingInput(
              key: ValueKey(rating),
              rating: rating,
              itemSize: 48,
              onChanged: (value) => setState(() => rating = value),
            ),
            if (_showResetAction) ...[
              const SizedBox(height: 20),
              TextButton(
                key: const Key('resetRatingButton'),
                onPressed: _resetRating,
                child: const Text('다시 선택하기'),
              ),
            ],
            SizedBox(height: _showResetAction ? 24 : 36),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(rating),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieNotFound extends StatelessWidget {
  const _MovieNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('영화 상세'),
      ),
      body: const Center(child: Text('영화를 찾을 수 없습니다.')),
    );
  }
}
