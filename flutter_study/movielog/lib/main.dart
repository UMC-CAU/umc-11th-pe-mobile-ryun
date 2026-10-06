import 'package:flutter/material.dart';

import 'data/mock_movies.dart';
import 'movielog_app.dart';

void main() {
  for (final movie in movies) {
    debugPrint(movie.title);
  }

  final nickname = safeNickname(null);
  debugPrint('안녕하세요, $nickname님!');

  runApp(const MovieLogApp());
}

String safeNickname(String? nickname) => nickname ?? '륜';
