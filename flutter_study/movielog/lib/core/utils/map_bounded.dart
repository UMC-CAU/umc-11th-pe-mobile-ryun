Future<List<R>> mapBounded<T, R>(
  List<T> values,
  Future<R> Function(T) action, {
  int limit = 5,
}) async {
  if (limit < 1) throw ArgumentError.value(limit);
  final output = List<R?>.filled(values.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < values.length) {
      final index = next++;
      output[index] = await action(values[index]);
    }
  }

  await Future.wait(
    List.generate(
      values.length < limit ? values.length : limit,
      (_) => worker(),
    ),
  );
  return output.cast<R>();
}
