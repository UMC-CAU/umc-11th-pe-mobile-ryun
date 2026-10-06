import 'package:flutter/material.dart';

import 'movie_list_state_body.dart';

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const MovieListStateBody(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('조건에 맞는 영화가 없습니다.', textAlign: TextAlign.center),
      ),
    );
  }
}
