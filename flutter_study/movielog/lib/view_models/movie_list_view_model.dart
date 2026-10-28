import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  List<int>? selectedGenreIds;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;
  bool _disposed = false;
  bool _genresLoaded = false;
  List<TmdbMovieDto> _lastSuccessfulMovies = const [];
  List<int>? _lastSuccessfulGenreIds;
  bool _hasSuccessfulResult = false;
  bool errorDialogPending = false;
  bool get isLoading => status == MovieListLoadStatus.loading;

  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    List<int>? genreIds,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;
    while (!_disposed && byId.length < 30 && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );
      if (_disposed) return const [];
      for (final movie in page.results) {
        byId.putIfAbsent(movie.id, () => movie);
        if (byId.length == 30) break;
      }
      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }
    return List.unmodifiable(byId.values);
  }

  Future<void> loadInitial() => _load();
  Future<void> refresh() => _load();
  Future<void> retry() => _load();

  Future<void> selectGenres(List<int>? genreIds) async {
    if (_disposed || status == MovieListLoadStatus.loading) return;
    final normalized = genreIds?.toSet().toList();
    normalized?.sort();
    final selection = normalized == null || normalized.isEmpty
        ? null
        : List<int>.unmodifiable(normalized);
    if (listEquals(selectedGenreIds, selection)) return;
    selectedGenreIds = selection;
    await _load(clearMovies: true);
  }

  // Cancel restores the successful list's genre labels as well as its contents.
  void cancelError() {
    if (_disposed || !errorDialogPending) return;
    errorDialogPending = false;
    message = null;
    if (_hasSuccessfulResult) {
      selectedGenreIds = _lastSuccessfulGenreIds;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    }
    notifyListeners();
  }

  Future<void> _load({bool clearMovies = false}) async {
    if (_disposed || status == MovieListLoadStatus.loading) return;
    final requestedGenres = selectedGenreIds;
    status = MovieListLoadStatus.loading;
    message = null;
    errorDialogPending = false;
    if (clearMovies) movies = const [];
    notifyListeners();
    try {
      if (!_genresLoaded) {
        final result = await _service.fetchGenres();
        if (_disposed) return;
        genres = List.unmodifiable(result);
        _genresLoaded = true;
      }
      final result = await fetchUpToThirtyMovies(genreIds: requestedGenres);
      if (_disposed) return;
      movies = result;
      _lastSuccessfulMovies = result;
      _lastSuccessfulGenreIds = requestedGenres;
      _hasSuccessfulResult = true;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (_disposed) return;
      status = MovieListLoadStatus.error;
      movies = _lastSuccessfulMovies;
      errorDialogPending = true;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
