import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../widgets/tmdb_poster_image.dart';

class TmdbMovieCard extends StatelessWidget {
  const TmdbMovieCard({super.key, required this.movie, this.rank});
  final TmdbMovieDto movie;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TmdbPosterImage(
                    posterPath: movie.posterPath,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (rank != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: CircleAvatar(radius: 14, child: Text('$rank')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '★ ${movie.voteAverage.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
