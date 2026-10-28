import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import 'widgets/genre_filter_chip.dart';
import 'widgets/genre_filter_sheet.dart';
import 'widgets/movie_grid_layout.dart';
import 'widgets/movie_list_empty.dart';
import 'widgets/movie_list_error.dart';
import 'widgets/movie_list_loading.dart';
import 'widgets/movie_request_error_dialog.dart';
import 'widgets/tmdb_movie_card.dart';

class TmdbMovieListScreen extends StatefulWidget {
  const TmdbMovieListScreen({super.key});
  @override
  State<TmdbMovieListScreen> createState() => _TmdbMovieListScreenState();
}

class _TmdbMovieListScreenState extends State<TmdbMovieListScreen> {
  MovieListViewModel? _viewModel;
  bool _dialogScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<MovieListViewModel>();
    if (!identical(vm, _viewModel)) {
      _viewModel?.removeListener(_handleState);
      _viewModel = vm;
      vm.addListener(_handleState);
    }
    _handleState();
  }

  void _handleState() {
    final vm = _viewModel;
    if (!mounted || vm == null || !vm.errorDialogPending || _dialogScheduled) {
      return;
    }
    _dialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !identical(vm, _viewModel) || !vm.errorDialogPending) {
        _dialogScheduled = false;
        return;
      }
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const MovieRequestErrorDialog(),
      );
      _dialogScheduled = false;
      if (!mounted || !identical(vm, _viewModel)) return;
      if (retry == true) {
        await vm.retry();
      } else {
        vm.cancelError();
      }
    });
  }

  Future<void> _openGenres() async {
    final vm = context.read<MovieListViewModel>();
    if (vm.isLoading || vm.errorDialogPending) return;
    final selected = await showModalBottomSheet<Set<int>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => GenreFilterSheet(
        genres: vm.genres,
        initialSelectedGenres: (vm.selectedGenreIds ?? const <int>[]).toSet(),
      ),
    );
    if (!mounted || selected == null) return;
    await vm.selectGenres(selected.toList());
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleState);
    super.dispose();
  }

  Widget _contents(MovieListViewModel vm) {
    if (vm.movies.isNotEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          key: const PageStorageKey('tmdb-movie-grid'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: MovieGridLayout.padding,
          gridDelegate: MovieGridLayout.delegate(constraints.maxWidth),
          itemCount: vm.movies.length,
          itemBuilder: (context, index) =>
              TmdbMovieCard(movie: vm.movies[index]),
        ),
      );
    }
    return switch (vm.status) {
      MovieListLoadStatus.idle ||
      MovieListLoadStatus.loading => const MovieListLoading(),
      MovieListLoadStatus.error => MovieListError(onRetry: () => vm.retry()),
      MovieListLoadStatus.empty ||
      MovieListLoadStatus.success => const MovieListEmpty(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<MovieListViewModel>(
            builder: (context, vm, child) => IconButton(
              key: const Key('genreFilterButton'),
              tooltip: '장르 필터',
              onPressed: vm.isLoading || vm.errorDialogPending
                  ? null
                  : _openGenres,
              icon: const Icon(Icons.filter_list, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<MovieListViewModel>(
        builder: (context, vm, child) {
          final disabled = vm.isLoading || vm.errorDialogPending;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GenreFilterChip(
                              label: '전체',
                              selected: vm.selectedGenreIds == null,
                              onSelected: disabled
                                  ? null
                                  : (_) => vm.selectGenres(null),
                            ),
                            for (final genre in vm.genres)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GenreFilterChip(
                                  label: genre.name,
                                  selected:
                                      vm.selectedGenreIds?.contains(genre.id) ??
                                      false,
                                  onSelected: disabled
                                      ? null
                                      : (selected) {
                                          final ids = {...?vm.selectedGenreIds};
                                          if (selected) {
                                            ids.add(genre.id);
                                          } else {
                                            ids.remove(genre.id);
                                          }
                                          vm.selectGenres(ids.toList());
                                        },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.isLoading && vm.movies.isNotEmpty)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => vm.refresh(),
                  notificationPredicate: (notification) =>
                      !vm.isLoading &&
                      !vm.errorDialogPending &&
                      notification.depth == 0,
                  child: ScrollConfiguration(
                    // Cards contain no selectable text; also allow mouse drag
                    // refresh for desktop and emulator users.
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        ...ScrollConfiguration.of(context).dragDevices,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: _contents(vm),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
