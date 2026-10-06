import 'package:flutter/material.dart';

// 내용이 한 화면보다 짧은 Empty/Error에서도 당겨서 새로고침할 수 있다.
class MovieListStateBody extends StatelessWidget {
  const MovieListStateBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
      ],
    );
  }
}
