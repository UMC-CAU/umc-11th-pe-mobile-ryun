import 'package:flutter/material.dart';

import '../../models/movie.dart';

enum MovieCardVariant { grid, ranked }

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.variant = MovieCardVariant.grid,
    this.rank,
  });

  final Movie movie;
  final VoidCallback onTap;
  final MovieCardVariant variant;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    movie.posterAsset,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (variant == MovieCardVariant.grid)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _PosterBadge(
                      label: '★ ${movie.averageRating.toStringAsFixed(1)}',
                    ),
                  ),
                if (variant == MovieCardVariant.ranked && rank != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _PosterBadge(label: '$rank'),
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
          const SizedBox(height: 2),
          if (variant == MovieCardVariant.grid)
            Text(
              '${movie.year} · ${movie.genre}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Color(0xFFC89420)),
                const SizedBox(width: 4),
                Text(
                  movie.averageRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PosterBadge extends StatelessWidget {
  const _PosterBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
