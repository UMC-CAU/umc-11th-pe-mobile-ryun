import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/week8_ui.dart';
import '../widgets/workbook_ui.dart';
import '../theme/week6_style.dart';
import 'widgets/genre_filter_sheet.dart';
import 'widgets/tmdb_movie_card.dart';

class PagedMovieListScreen extends StatefulWidget {
  const PagedMovieListScreen({
    super.key,
    this.search = false,
    this.challenge = true,
  });
  final bool search;
  final bool challenge;
  @override
  State<PagedMovieListScreen> createState() => _PagedMovieListScreenState();
}

class _PagedMovieListScreenState extends State<PagedMovieListScreen> {
  final _scroll = ScrollController();
  final _text = TextEditingController();
  Timer? _debounce;
  List<TmdbGenreDto> _genres = [];
  bool _genreError = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_nearEnd);
    if (!widget.search) _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final result = await context.read<TmdbMovieService>().fetchGenres();
      if (mounted) {
        setState(() {
          _genres = result;
          _genreError = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _genreError = true);
    }
  }

  void _nearEnd() {
    if (!widget.challenge || widget.search || !_scroll.hasClients) return;
    final vm = context.read<PagedMoviesViewModel>();
    if (_scroll.position.extentAfter < 300 && vm.loadMoreError == null) {
      vm.loadNextPage();
    }
  }

  void _submit(String value) {
    _debounce?.cancel();
    context.read<PagedMoviesViewModel>().loadInitial(query: value);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _changed(String value) {
    _debounce?.cancel();
    if (!widget.challenge) return;
    // Invalidate in-flight results immediately, including when input is cleared.
    context.read<PagedMoviesViewModel>().loadInitial(query: '');
    if (value.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _submit(value);
    });
  }

  Future<void> _filter() async {
    final vm = context.read<PagedMoviesViewModel>();
    final selected = await showModalBottomSheet<Set<int>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GenreFilterSheet(
        genres: _genres,
        initialSelectedGenres: vm.condition.genres.toSet(),
      ),
    );
    if (!mounted || selected == null) return;
    await vm.loadInitial(genres: selected.toList());
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.removeListener(_nearEnd);
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagedMoviesViewModel>();
    return Scaffold(
      appBar: Week8Ui.appBar(
        widget.search ? '영화 검색' : '영화',
        onBack: widget.search ? () => context.pop() : null,
        actions: [
          if (!widget.search) ...[
            IconButton(
              tooltip: '검색',
              onPressed: () => context.push('/movies/search'),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: '장르 필터',
              onPressed: _genres.isEmpty ? null : _filter,
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (widget.search)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const Key('movieSearchField'),
                controller: _text,
                textInputAction: TextInputAction.search,
                onSubmitted: _submit,
                onChanged: _changed,
                style: Week6Style.text(14, 20),
                decoration: Week8Ui.input(hint: '영화 제목을 검색해 보세요').copyWith(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: '검색어 지우기',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _text.clear();
                      _submit('');
                    },
                  ),
                ),
              ),
            ),
          if (!widget.search)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ChoiceChip(
                      label: const Text('전체'),
                      selected: vm.condition.genres.isEmpty,
                      onSelected: (_) {
                        vm.loadInitial();
                        if (_scroll.hasClients) _scroll.jumpTo(0);
                      },
                    ),
                  ),
                  for (final genre in _genres)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(genre.name),
                        selected: vm.condition.genres.contains(genre.id),
                        onSelected: (selected) {
                          final ids = vm.condition.genres.toSet();
                          selected ? ids.add(genre.id) : ids.remove(genre.id);
                          vm.loadInitial(genres: ids.toList());
                          if (_scroll.hasClients) _scroll.jumpTo(0);
                        },
                      ),
                    ),
                ],
              ),
            ),
          if (_genreError)
            TextButton(onPressed: _loadGenres, child: const Text('장르 다시 불러오기')),
          Expanded(child: _body(vm)),
        ],
      ),
    );
  }

  Widget _body(PagedMoviesViewModel vm) {
    if (vm.phase == LoadPhase.idle) {
      return const WorkbookStateBody(
        message: '검색어를 입력해 주세요.',
        icon: Icons.search,
      );
    }
    if (vm.phase == LoadPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.phase == LoadPhase.error) {
      return WorkbookStateBody(
        message: widget.search ? '검색 결과를 불러오지 못했습니다.' : '영화를 불러오지 못했습니다.',
        onRetry: vm.retry,
      );
    }
    if (vm.phase == LoadPhase.empty) {
      return WorkbookStateBody(
        message: widget.search ? '검색 결과가 없습니다.' : '선택한 장르의 영화가 없습니다.',
      );
    }
    return RefreshIndicator(
      onRefresh: vm.retry,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.separated(
              itemBuilder: (context, index) => TmdbMovieCard(
                key: ValueKey(vm.movies[index].id),
                movie: vm.movies[index],
                horizontal: true,
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemCount: vm.movies.length,
            ),
          ),
          SliverToBoxAdapter(
            child: MoviePageFooter(
              model: vm,
              automatic: widget.challenge && !widget.search,
            ),
          ),
        ],
      ),
    );
  }
}
