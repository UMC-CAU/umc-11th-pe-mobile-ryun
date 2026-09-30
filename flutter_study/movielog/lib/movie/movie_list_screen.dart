import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import 'widgets/movie_card.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key, this.selectedGenres = const []});

  final List<String> selectedGenres;

  List<String> get _genres =>
      movies.map((movie) => movie.genre).toSet().toList(growable: false);

  List<Movie> get _filteredMovies {
    if (selectedGenres.isEmpty) return movies;
    return movies
        .where((movie) => selectedGenres.contains(movie.genre))
        .toList(growable: false);
  }

  Future<void> _openGenreFilter(BuildContext context) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => GenreFilterSheet(
        genres: _genres,
        initialSelectedGenres: selectedGenres.toSet(),
      ),
    );

    if (!context.mounted || result == null) return;

    final location = Uri(
      path: '/movies',
      queryParameters: result.isEmpty
          ? null
          : <String, dynamic>{'genre': result.toList(growable: false)},
    ).toString();
    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('영화'),
        actions: [
          IconButton(
            tooltip: '검색',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('검색 기능은 준비 중입니다.'),
                  duration: Duration(milliseconds: 1500),
                ),
              );
            },
            icon: const Icon(Icons.search, color: AppColors.iconGray),
          ),
        ],
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: IconButton(
                key: const Key('genreFilterButton'),
                tooltip: '장르 필터',
                onPressed: () => _openGenreFilter(context),
                icon: const Icon(Icons.filter_list, color: AppColors.primary),
              ),
            ),
          ),
          Expanded(child: MovieGrid(movies: _filteredMovies)),
        ],
      ),
    );
  }
}

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelectedGenres,
  });

  final List<String> genres;
  final Set<String> initialSelectedGenres;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> _draftGenres = Set.of(widget.initialSelectedGenres);

  void _toggleGenre(String genre, bool selected) {
    setState(() {
      if (selected) {
        _draftGenres.add(genre);
      } else {
        _draftGenres.remove(genre);
      }
    });
  }

  void _applyFilter() {
    Navigator.of(context).pop(Set<String>.of(_draftGenres));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '장르 필터',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '여러 장르를 선택할 수 있어요',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.genres.length,
                itemBuilder: (context, index) {
                  final genre = widget.genres[index];
                  return CheckboxListTile(
                    value: _draftGenres.contains(genre),
                    title: Text(genre),
                    onChanged: (value) => _toggleGenre(genre, value ?? false),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('applyGenreFilterButton'),
                  onPressed: _applyFilter,
                  child: const Text('확인'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 600
            ? 3
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: movies.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 20,
            childAspectRatio: 0.58,
          ),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return MovieCard(
              movie: movie,
              onTap: () => context.push('/movies/${movie.id}'),
            );
          },
        );
      },
    );
  }
}
