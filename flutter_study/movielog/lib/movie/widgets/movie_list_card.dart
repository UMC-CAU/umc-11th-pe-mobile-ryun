import 'package:flutter/material.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../theme/week6_style.dart';
import '../../widgets/tmdb_poster_image.dart';

class MovieListCard extends StatelessWidget {
  const MovieListCard({
    super.key,
    this.movie,
    required this.movieId,
    this.onTap,
    this.isFavorite = false,
    this.onRetry,
    this.retrying = false,
  });
  final TmdbMovieDto? movie;
  final int movieId;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onRetry;
  final bool retrying;
  @override
  Widget build(BuildContext context) => Material(
    color: Week6Style.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Week6Style.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TmdbPosterImage(
                posterPath: movie?.posterPath,
                width: 78,
                height: 120,
                placeholderColor: const Color(0xFFEEE8F5),
                showPlaceholderIcon: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 #$movieId',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Week6Style.text(18, 25, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie == null
                        ? '영화 정보를 불러오지 못했습니다.'
                        : movie!.overview.isEmpty
                        ? '영화 소개가 아직 없습니다.'
                        : movie!.overview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Week6Style.text(13, 21, color: Week6Style.body),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isFavorite ? '즐겨찾기한 영화' : '영화 상세 보기',
                    style: Week6Style.text(
                      14,
                      20,
                      color: Week6Style.primary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (onRetry != null)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: retrying ? null : onRetry,
                      child: Text(retrying ? '불러오는 중…' : '정보 다시 불러오기'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
