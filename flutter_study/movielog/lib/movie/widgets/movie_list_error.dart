import 'package:flutter/material.dart';

import 'movie_list_state_body.dart';

class MovieListError extends StatelessWidget {
  const MovieListError({
    super.key,
    required this.onRetry,
    this.isTimeout = false,
  });

  final VoidCallback onRetry;
  final bool isTimeout;

  @override
  Widget build(BuildContext context) {
    return MovieListStateBody(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(
              isTimeout ? '요청 시간이 초과되었습니다. 다시 시도해 주세요.' : '영화 목록을 불러오지 못했습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
