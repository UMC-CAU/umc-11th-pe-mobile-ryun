import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/rating_with_movie.dart';

const int sampleMemberId = 1; // 인증된 ‘내 계정’이 아닌 학습용 데이터입니다.

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? refreshWarning;
  bool isWriting = false;

  Future<void> _refreshAfterWrite() async {
    await load();
    if (_disposed) return;
    refreshWarning = status == MyRatingsLoadStatus.error
        ? '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.'
        : null;
    notifyListeners();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) => _write(
    () => _service.updateRating(
      memberId: memberId,
      ratingId: ratingId,
      score: score,
      comment: comment,
    ),
  );

  Future<void> deleteRating(int ratingId) => _write(
    () => _service.deleteRating(memberId: memberId, ratingId: ratingId),
  );

  Future<Set<int>> deleteSelectedRatings(Set<int> ratingIds) async {
    if (_disposed || isWriting || ratingIds.isEmpty) {
      return {...ratingIds};
    }
    final targets = {...ratingIds};
    final deleted = <int>{};
    isWriting = true;
    notifyListeners();
    try {
      for (final ratingId in targets) {
        if (_disposed) break;
        try {
          await _service.deleteRating(memberId: memberId, ratingId: ratingId);
          deleted.add(ratingId);
        } on DioException {
          // A rejected request must not prevent the other selections being tried.
        } on StateError {
          // An unexpected success status also leaves the card available for retry.
        }
      }
      if (!_disposed && deleted.isNotEmpty) {
        ratings = ratings
            .where((entry) => !deleted.contains(entry.rating.ratingId))
            .toList();
        if (ratings.isEmpty) {
          status = MyRatingsLoadStatus.empty;
          message = null;
        }
      }
      return targets.difference(deleted);
    } finally {
      isWriting = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _write(Future<void> Function() action) async {
    if (_disposed || isWriting) throw StateError('처리 중입니다. 잠시 기다려 주세요.');
    isWriting = true;
    notifyListeners();
    try {
      try {
        await action();
      } on DioException catch (error) {
        if (_disposed) rethrow;
        final writeMessage = writeErrorMessage(error);
        if (shouldRefreshAfterRatingError(error)) await load();
        if (!_disposed) {
          message = writeMessage;
          notifyListeners();
        }
        rethrow;
      }
      // A refresh failure is never rethrown as a failed write.
      await _refreshAfterWrite();
    } finally {
      isWriting = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;
      final entries = <RatingWithMovie>[];
      var missingMovies = 0;
      final attemptedMovieIds = <int>{};
      // 같은 movieId는 캐시를 사용하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;
        if (!_movieCache.containsKey(rating.movieId) &&
            attemptedMovieIds.add(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // 일시적 네트워크 실패는 캐시하지 않습니다. 다음 로딩에서 재시도합니다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_disposed || version != _requestVersion) return;
      ratings = entries;
      refreshWarning = null;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } on Object {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 목록 응답을 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
