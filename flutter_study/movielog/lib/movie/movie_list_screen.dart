import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/genre_preference.dart';
import '../data/sort_preference.dart';
import '../models/movie.dart';
import '../models/movie_sort_order.dart';
import '../services/fake_movie_service.dart';
import '../theme/app_colors.dart';
import 'widgets/genre_filter_chip.dart';
import 'widgets/movie_card.dart';
import 'widgets/movie_grid_layout.dart';
import 'widgets/movie_list_empty.dart';
import 'widgets/movie_list_error.dart';
import 'widgets/movie_list_loading.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    this.selectedGenres,
    this.movieService = const FakeMovieService(),
    this.genrePreference,
    this.sortPreference,
    this.requestTimeout = const Duration(seconds: 5),
  });

  // 주소에 장르가 없으면(null) 최초 진입 시 마지막 저장값을 복원한다.
  final List<String>? selectedGenres;
  final FakeMovieService movieService;
  final GenrePreference? genrePreference;
  final SortPreference? sortPreference;
  final Duration requestTimeout;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final GenrePreference _genrePreference;
  late final SortPreference _sortPreference;
  late Future<List<Movie>> _moviesFuture;
  Set<String> _selectedGenres = {};
  MovieSortOrder _sortOrder = MovieSortOrder.original;
  bool _hasRestoredPreferences = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _genrePreference = widget.genrePreference ?? GenrePreference();
    _sortPreference = widget.sortPreference ?? SortPreference();
    _moviesFuture = _loadMovies();
  }

  Future<List<Movie>> _loadMovies() async {
    _isLoading = true;
    try {
      final loadedMovies = await widget.movieService.fetchMovies().timeout(
        widget.requestTimeout,
      );

      if (!_hasRestoredPreferences) {
        final savedGenres = await _genrePreference.read();
        final savedSort = await _sortPreference.read();
        if (!mounted) return loadedMovies;

        _selectedGenres = (widget.selectedGenres ?? savedGenres).toSet();
        _sortOrder = savedSort;
        _hasRestoredPreferences = true;
        // Future 완료 시 FutureBuilder가 다시 그리므로 setState는 필요 없다.
      }
      return loadedMovies;
    } finally {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.selectedGenres, widget.selectedGenres)) {
      final genres = (widget.selectedGenres ?? const <String>[]).toSet();
      if (_hasRestoredPreferences && !setEquals(_selectedGenres, genres)) {
        _selectedGenres = genres;
        _saveGenres(genres);
      }
    }
  }

  void _retry() {
    if (_isLoading) return;
    setState(() {
      _moviesFuture = _loadMovies();
    });
  }

  Future<void> _refresh() async {
    _retry();
    try {
      // 실제 요청이 끝날 때까지 RefreshIndicator를 유지한다.
      await _moviesFuture;
    } catch (_) {
      // 오류는 FutureBuilder가 표시한다. 새로고침 콜백에서는 전파하지 않는다.
    }
  }

  Future<void> _selectSort(MovieSortOrder order) async {
    setState(() => _sortOrder = order);
    try {
      await _sortPreference.save(order);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정렬 방식을 저장하지 못했습니다. 다시 선택해 주세요.')),
      );
    }
  }

  Future<void> _saveGenres(Set<String> genres) async {
    try {
      await _genrePreference.save(genres.toList(growable: false));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장르를 저장하지 못했습니다. 다시 선택해 주세요.')),
      );
    }
  }

  void _selectGenres(Set<String> genres) {
    setState(() => _selectedGenres = Set.of(genres));
    _saveGenres(genres);

    final location = Uri(
      path: '/movies',
      queryParameters: genres.isEmpty
          ? null
          : <String, dynamic>{'genre': genres.toList(growable: false)},
    ).toString();
    context.go(location);
  }

  // 3주차 바텀시트 방식 보관. 복원 시 아래 메서드, 버튼, GenreFilterSheet의
  // 주석을 함께 해제한다. 4주차에서는 장르 Chip으로 바로 선택한다.
  /*
  Future<void> _openGenreFilter(List<String> genres) async {
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
        genres: genres,
        initialSelectedGenres: _selectedGenres,
      ),
    );

    if (!mounted || result == null) return;
    _selectGenres(result);
  }
  */

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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Movie>>(
          future: _moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MovieListLoading();
            }
            if (snapshot.hasError) {
              return MovieListError(
                onRetry: _retry,
                isTimeout: snapshot.error is TimeoutException,
              );
            }

            final movies = snapshot.data ?? const <Movie>[];
            // 저장된 장르가 목록에서 사라져도 Chip으로 해제할 수 있다.
            final genres = {
              ...movies.map((movie) => movie.genre),
              ...movies.map((movie) => movie.secondaryGenre),
              ..._selectedGenres,
            }.toList(growable: false);
            final filteredMovies = _selectedGenres.isEmpty
                ? movies
                : movies
                      // 선택한 장르를 영화가 모두 가지고 있어야 한다 (AND).
                      .where(
                        (movie) => _selectedGenres.every(
                          (genre) =>
                              movie.genre == genre ||
                              movie.secondaryGenre == genre,
                        ),
                      )
                      .toList(growable: false);
            final sortedMovies = _sortOrder.apply(filteredMovies);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              GenreFilterChip(
                                label: '전체',
                                selected: _selectedGenres.isEmpty,
                                onSelected: (_) => _selectGenres({}),
                              ),
                              for (final genre in genres)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: GenreFilterChip(
                                    label: genre,
                                    selected: _selectedGenres.contains(genre),
                                    onSelected: (selected) {
                                      final selection = Set.of(_selectedGenres);
                                      if (selected) {
                                        selection.add(genre);
                                      } else {
                                        selection.remove(genre);
                                      }
                                      _selectGenres(selection);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // 3주차 바텀시트 버튼 보관 (4주차에서는 Chip만 사용).
                      /*
                    IconButton(
                      key: const Key('genreFilterButton'),
                      tooltip: '장르 필터',
                      onPressed: () => _openGenreFilter(genres),
                      icon: const Icon(
                        Icons.filter_list,
                        color: AppColors.primary,
                      ),
                    ),
                    */
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<MovieSortOrder>(
                      key: const Key('movieSortButton'),
                      tooltip: '정렬 방식',
                      initialValue: _sortOrder,
                      onSelected: _selectSort,
                      itemBuilder: (context) => [
                        for (final order in MovieSortOrder.values)
                          CheckedPopupMenuItem(
                            value: order,
                            checked: _sortOrder == order,
                            child: Text(order.label),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort, size: 18),
                            const SizedBox(width: 6),
                            Text(_sortOrder.label),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredMovies.isEmpty
                      ? const MovieListEmpty()
                      : MovieGrid(movies: sortedMovies),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// 3주차 바텀시트 Widget 보관. 다시 사용할 때 이 블록의 주석을 해제한다.
/*
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
      initialChildSize: 0.6,
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
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(left: 8, right: 20),
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
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('applyGenreFilterButton'),
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(56),
                  ),
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

*/

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: MovieGridLayout.padding,
          itemCount: movies.length,
          gridDelegate: MovieGridLayout.delegate(constraints.maxWidth),
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
