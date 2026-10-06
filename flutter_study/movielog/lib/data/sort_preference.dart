import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie_sort_order.dart';

class SortPreference {
  SortPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const sortOrderKey = 'movie_sort_order';
  final SharedPreferencesAsync _preferences;
  Future<void> _pendingSave = Future<void>.value();

  Future<MovieSortOrder> read() async {
    final name = await _preferences.getString(sortOrderKey);
    return MovieSortOrder.values.firstWhere(
      (order) => order.name == name,
      orElse: () => MovieSortOrder.original,
    );
  }

  Future<void> save(MovieSortOrder order) {
    // 연속 선택 시에도 마지막 선택이 마지막으로 저장된다.
    final save = _pendingSave.then(
      (_) => _preferences.setString(sortOrderKey, order.name),
    );
    _pendingSave = save.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return save;
  }
}
