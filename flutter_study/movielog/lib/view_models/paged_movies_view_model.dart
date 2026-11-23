import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'favorites_view_model.dart';

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel(this.api, {this.searchMode = false});
  final TmdbMovieService api;
  final bool searchMode;
  List<TmdbMovieDto> movies = [];
  LoadPhase phase = LoadPhase.idle;
  bool isLoadingMore = false;
  String? loadMoreError;
  int nextPage = 1;
  int totalPages = 0;
  int generation = 0;
  ({List<int> genres, String query}) condition = (genres: [], query: '');
  bool get hasMore => nextPage <= totalPages && nextPage <= 500;
  Future<void> loadInitial({List<int>? genres, String query = ''}) async {
    final version = ++generation;
    condition = (genres: List.unmodifiable(genres ?? []), query: query.trim());
    movies = [];
    nextPage = 1;
    totalPages = 0;
    isLoadingMore = false;
    loadMoreError = null;
    if (searchMode && condition.query.isEmpty) {
      phase = LoadPhase.idle;
      notifyIfAlive();
      return;
    }
    phase = LoadPhase.loading;
    notifyIfAlive();
    await _fetch(version, initial: true);
  }

  Future<void> retry() =>
      loadInitial(genres: condition.genres, query: condition.query);
  Future<void> loadNextPage() async {
    if (isDisposed || phase == LoadPhase.loading || isLoadingMore || !hasMore) {
      return;
    }
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    await _fetch(generation, initial: false);
  }

  Future<void> _fetch(int version, {required bool initial}) async {
    final page = nextPage;
    final request = condition;
    try {
      final result = searchMode
          ? await api.searchMovies(query: request.query, page: page)
          : await api.discoverMovies(page: page, genreIds: request.genres);
      if (isDisposed || version != generation) return;
      final ids = movies.map((movie) => movie.id).toSet();
      movies = [
        ...movies,
        ...result.results.where((movie) => ids.add(movie.id)),
      ];
      nextPage = page + 1;
      totalPages = result.totalPages;
      phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } on Object {
      if (isDisposed || version != generation) return;
      if (initial) {
        phase = LoadPhase.error;
      } else {
        loadMoreError = '추가 조회에 실패했습니다. 같은 페이지를 다시 시도해 주세요.';
      }
    } finally {
      if (!isDisposed && version == generation) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }
}
