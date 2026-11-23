import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/favorites_view_model.dart';
import '../movie/widgets/tmdb_movie_card.dart';
import '../movie/widgets/movie_list_card.dart';
import '../widgets/week8_ui.dart';
import '../widgets/workbook_ui.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    return Scaffold(
      appBar: Week8Ui.appBar('내 즐겨찾기', onBack: () => context.pop()),
      body: switch (vm.phase) {
        LoadPhase.idle ||
        LoadPhase.loading => const Center(child: CircularProgressIndicator()),
        LoadPhase.empty => const WorkbookStateBody(
          message: '아직 즐겨찾기한 영화가 없습니다.',
          detail: '영화 상세에서 북마크를 눌러 보세요.',
          icon: Icons.bookmark_border,
        ),
        LoadPhase.error => WorkbookStateBody(
          message: '즐겨찾기를 불러오지 못했습니다.',
          onRetry: vm.refresh,
        ),
        LoadPhase.success => RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (_, _) => const SizedBox(height: 20),
            itemCount: vm.items.length,
            itemBuilder: (context, index) {
              final item = vm.items[index];
              final movie = item.movie;
              if (movie == null) {
                return MovieListCard(
                  key: ValueKey(item.favorite.movieId),
                  movieId: item.favorite.movieId,
                  isFavorite: true,
                  retrying: vm.retrying.contains(item.favorite.movieId),
                  onRetry: () => vm.retryMovie(item.favorite.movieId),
                );
              }
              return TmdbMovieCard(
                key: ValueKey(movie.id),
                movie: movie,
                horizontal: true,
                isFavorite: true,
                onTap: () async {
                  await context.push('/movies/${movie.id}', extra: movie);
                  if (context.mounted) await vm.refresh();
                },
              );
            },
          ),
        ),
      },
    );
  }
}
