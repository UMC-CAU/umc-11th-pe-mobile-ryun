import 'package:flutter/material.dart';

import '../view_models/paged_movies_view_model.dart';
import 'movielog_button.dart';
import '../theme/week6_style.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({
    super.key,
    required this.model,
    this.automatic = false,
  });
  final PagedMoviesViewModel model;
  final bool automatic;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: model.isLoadingMore && automatic
        ? const Center(child: CircularProgressIndicator())
        : model.loadMoreError != null
        ? Column(
            children: [
              Text(model.loadMoreError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              MovieLogButton(onPressed: model.loadNextPage, label: '다시 시도'),
            ],
          )
        : !model.hasMore
        ? Center(
            child: Text(
              '모든 영화를 확인했습니다.',
              style: Week6Style.text(12, 18, color: Week6Style.hint),
            ),
          )
        : automatic
        ? const SizedBox(height: 24)
        : MovieLogButton(
            onPressed: model.loadNextPage,
            isLoading: model.isLoadingMore,
            label: '더 보기',
          ),
  );
}
