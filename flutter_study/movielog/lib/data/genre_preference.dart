import 'package:shared_preferences/shared_preferences.dart';

class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const selectedGenresKey = 'selected_genres';

  final SharedPreferencesAsync _preferences;
  Future<void> _pendingSave = Future<void>.value();

  Future<List<String>> read() async {
    return await _preferences.getStringList(selectedGenresKey) ?? <String>[];
  }

  Future<void> save(List<String> genres) {
    final selection = List<String>.of(genres);
    // 빠르게 연속 선택해도 마지막 선택이 마지막으로 저장되도록 순서를 지킨다.
    final save = _pendingSave.then(
      (_) => _preferences.setStringList(selectedGenresKey, selection),
    );
    // 한 번 저장에 실패해도 다음 선택은 저장할 수 있다.
    _pendingSave = save.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return save;
  }
}
