import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/data/sort_preference.dart';
import 'package:movielog/models/movie_sort_order.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

final class _FailingSortStore extends InMemorySharedPreferencesAsync {
  _FailingSortStore() : super.empty();

  bool failWrite = true;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    if (failWrite) return Future.error(StateError('저장 실패'));
    return super.setString(key, value, options);
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  final expectedOrders = {
    MovieSortOrder.original: [1, 2, 3, 4, 5, 6],
    MovieSortOrder.rating: [6, 3, 1, 4, 2, 5],
    MovieSortOrder.newest: [1, 2, 5, 3, 6, 4],
    MovieSortOrder.title: [4, 5, 1, 6, 3, 2],
  };

  for (final entry in expectedOrders.entries) {
    test('${entry.key.label}은 원본을 바꾸지 않고 일관된 순서로 정렬한다', () {
      expect(entry.key.apply(movies).map((movie) => movie.id), entry.value);
      expect(movies.map((movie) => movie.id), [1, 2, 3, 4, 5, 6]);
    });
  }

  test('저장값이 없거나 모르는 정렬 이름이면 기본순을 사용한다', () async {
    expect(await SortPreference().read(), MovieSortOrder.original);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          SortPreference.sortOrderKey: 'removed_option',
        });
    expect(await SortPreference().read(), MovieSortOrder.original);
  });

  test('연속 정렬 저장 후 새 객체에서도 마지막 선택을 읽는다', () async {
    final preference = SortPreference();
    await Future.wait([
      preference.save(MovieSortOrder.rating),
      preference.save(MovieSortOrder.newest),
      preference.save(MovieSortOrder.title),
    ]);
    expect(await SortPreference().read(), MovieSortOrder.title);
  });

  test('정렬 저장에 실패해도 다음 선택은 저장한다', () async {
    final store = _FailingSortStore();
    SharedPreferencesAsyncPlatform.instance = store;
    final preference = SortPreference();
    await expectLater(preference.save(MovieSortOrder.rating), throwsStateError);
    store.failWrite = false;
    await preference.save(MovieSortOrder.newest);
    expect(await SortPreference().read(), MovieSortOrder.newest);
  });
}
