import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../core/session/auth_session.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/sign_up_service.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel(this.api, this.session, this.movieId)
    : _sessionVersion = session.generation;
  final FavoriteApi api;
  final AuthSession session;
  final int movieId;
  final int _sessionVersion;
  bool isFavorite = false;
  bool busy = false;
  bool known = false;
  String? message;
  bool get alive =>
      !isDisposed && session.authenticated && session.current(_sessionVersion);

  Future<void> load() async {
    if (!alive || busy) return;
    busy = true;
    message = null;
    notifyIfAlive();
    try {
      final result = await api.check(movieId);
      if (!alive) return;
      isFavorite = result.isFavorite;
      known = true;
    } on Object {
      if (alive) {
        known = false;
        message = '즐겨찾기 여부를 확인하지 못했습니다. 다시 확인해 주세요.';
      }
    } finally {
      if (alive) {
        busy = false;
        notifyIfAlive();
      }
    }
  }

  Future<void> toggle() async {
    if (!alive || busy) return;
    if (!known) {
      await load();
      return;
    }
    busy = true;
    message = null;
    notifyIfAlive();
    try {
      if (isFavorite) {
        await api.remove(movieId);
      } else {
        await api.add(movieId);
      }
      if (!alive) return;
      isFavorite = !isFavorite;
      message = isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기를 해제했습니다.';
    } on DioException catch (error) {
      if (!alive) return;
      final code = errorCode(error);
      message = apiErrorMessage(error, fallback: '즐겨찾기를 저장하지 못했습니다.');
      // Never replay a write whose response may have been lost.
      known = false;
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final status = await api.check(movieId);
          if (!alive) return;
          isFavorite = status.isFavorite;
          known = true;
        } on Object {
          /* Retry button performs GET only. */
        }
      }
    } on Object {
      if (alive) {
        known = false;
        message = '저장 결과를 다시 확인해 주세요.';
      }
    } finally {
      if (alive) {
        busy = false;
        notifyIfAlive();
      }
    }
  }
}
