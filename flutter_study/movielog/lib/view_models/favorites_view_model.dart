import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../core/utils/map_bounded.dart';
import '../core/session/auth_session.dart';
import '../data/models/favorite_models.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum LoadPhase { idle, loading, success, empty, error }

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel(this.api, this.movies, this.session)
    : _sessionVersion = session.generation;
  final FavoriteApi api;
  final TmdbMovieService movies;
  final AuthSession session;
  final int _sessionVersion;
  int _generation = 0;
  final Map<int, TmdbMovieDto> _cache = {};
  final Set<int> retrying = {};
  List<FavoriteListItem> items = [];
  LoadPhase phase = LoadPhase.idle;
  bool get alive =>
      !isDisposed && session.authenticated && session.current(_sessionVersion);
  Future<void> refresh() async {
    if (!alive) return;
    final version = ++_generation;
    items = [];
    retrying.clear();
    phase = LoadPhase.loading;
    notifyIfAlive();
    try {
      final favorites = await api.fetchFavorites();
      if (!alive || version != _generation) return;
      final result = await mapBounded(favorites, (favorite) async {
        TmdbMovieDto? movie = _cache[favorite.movieId];
        try {
          movie ??= await movies.fetchMovieDetail(favorite.movieId);
        } on Object {
          /* One failed movie remains a retryable card. */
        }
        return FavoriteListItem(favorite, movie);
      });
      if (!alive || version != _generation) return;
      for (final item in result) {
        if (item.movie != null) _cache[item.favorite.movieId] = item.movie!;
      }
      items = result;
      phase = result.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } on Object {
      if (alive && version == _generation) phase = LoadPhase.error;
    } finally {
      if (alive && version == _generation) notifyIfAlive();
    }
  }

  Future<void> retryMovie(int id) async {
    if (!alive || !retrying.add(id)) return;
    final version = _generation;
    notifyIfAlive();
    try {
      final movie = await movies.fetchMovieDetail(id);
      if (!alive || version != _generation) return;
      _cache[id] = movie;
      items = items
          .map(
            (item) => item.favorite.movieId == id
                ? FavoriteListItem(item.favorite, movie)
                : item,
          )
          .toList();
    } on Object {
      /* Preserve the failed card and its retry action. */
    } finally {
      if (alive && version == _generation) {
        retrying.remove(id);
        notifyIfAlive();
      }
    }
  }
}
