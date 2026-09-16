import 'package:flutter/material.dart';

import 'start_screen.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  static const _purple = Color(0xFF4F378A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _purple),
      ),
      home: const StartScreen(),
    );
  }
}
