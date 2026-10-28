import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../movie/widgets/tmdb_movie_card.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/tmdb_poster_image.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('MovieLog'),
          actions: [
            IconButton(
              tooltip: '검색',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('검색 기능은 준비 중입니다.')),
                );
              },
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        body: Consumer<MovieHomeViewModel>(
          builder: (context, vm, child) {
            if (vm.status == MovieHomeLoadStatus.idle ||
                vm.status == MovieHomeLoadStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.status == MovieHomeLoadStatus.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vm.message ?? '인기 영화를 불러오지 못했어요.'),
                    FilledButton(
                      onPressed: () =>
                          context.read<MovieHomeViewModel>().loadPopular(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }
            if (vm.status == MovieHomeLoadStatus.empty) {
              return const Center(child: Text('인기 영화가 없어요.'));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  '오늘은 어떤\n영화를 볼까요?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                FeaturedMovieCard(movie: vm.popularMovies.first),
                const SizedBox(height: 28),
                PopularMoviesSection(movies: vm.popularMovies),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FeaturedMovieCard extends StatelessWidget {
  const FeaturedMovieCard({super.key, required this.movie});

  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    void openDetail() => context.push('/movies/${movie.id}', extra: movie);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: openDetail,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: double.infinity,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6000000)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '인기 영화',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '★ ${movie.voteAverage.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: openDetail,
                        icon: const Icon(Icons.info),
                        label: const Text('상세보기'),
                      ),
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
}

class PopularMoviesSection extends StatelessWidget {
  const PopularMoviesSection({super.key, required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '인기 영화',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: AppColors.black),
            ),
            TextButton(
              onPressed: () => context.go('/movies'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('전체보기'), Icon(Icons.chevron_right, size: 18)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return SizedBox(
                width: 145,
                child: TmdbMovieCard(movie: movie, rank: index + 1),
              );
            },
          ),
        ),
      ],
    );
  }
}
