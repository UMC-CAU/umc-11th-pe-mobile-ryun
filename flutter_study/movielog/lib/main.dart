import 'package:flutter/material.dart';

import 'movielog_app.dart';

void main() {
  // Mission 2: Dart 기본 문법 연습
  final movies = <Movie>[
    const Movie(title: '호프', rating: 7.35),
    const Movie(title: '스파이더맨: 브랜드 뉴 데이', rating: 8.98),
    const Movie(title: '오디세이', rating: 9.06),
  ];

  for (final movie in movies) {
    debugPrint(movie.title);
  }

  final nickname = safeNickname(null);
  debugPrint('안녕하세요, $nickname님!');

  runApp(const MovieLogApp());
}

class Movie {
  const Movie({required this.title, required this.rating});

  final String title;
  final double rating;
}

String safeNickname(String? nickname) => nickname ?? '륜';
