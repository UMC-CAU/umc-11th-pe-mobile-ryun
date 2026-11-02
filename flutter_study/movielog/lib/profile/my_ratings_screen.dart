import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/week6_app_bar.dart';
import '../theme/week6_style.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Week6Style.background,
    appBar: Week6AppBar(
      title: '내가 등록한 평점',
      centerTitle: true,
      onBack: () => context.canPop() ? context.pop() : context.go('/my'),
    ),
    body: Consumer<MyRatingsViewModel>(
      builder: (context, model, _) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '학습용 memberId 1의 공개 샘플 평점입니다.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                height: 16 / 11,
                color: Week6Style.body,
              ),
            ),
          ),
          Expanded(
            child: switch (model.status) {
              MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              MyRatingsLoadStatus.empty => const Center(
                child: Text('아직 등록한 평점이 없습니다.'),
              ),
              MyRatingsLoadStatus.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(model.message!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      MovieLogButton(label: '다시 시도', onPressed: model.load),
                    ],
                  ),
                ),
              ),
              MyRatingsLoadStatus.success => RefreshIndicator(
                onRefresh: model.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (model.message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(model.message!),
                      ),
                    ...model.ratings.map((entry) {
                      final rating = entry.rating;
                      return Card(
                        key: ValueKey('rating-${rating.ratingId}'),
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Week6Style.border,
                            width: 2,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: TmdbPosterImage(
                                  posterPath: entry.movie?.posterPath,
                                  width: 82,
                                  height: 124,
                                  placeholderColor: Week6Style.placeholder,
                                  showPlaceholderIcon: false,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.movie?.title ??
                                          '영화 #${rating.movieId}',
                                      style: Week6Style.text(
                                        17,
                                        23,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '별점 ${rating.score} / 5',
                                      style: Week6Style.text(
                                        14,
                                        19,
                                        color: Week6Style.primary,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    if (rating.comment != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          rating.comment!,
                                          style: Week6Style.text(
                                            13,
                                            18,
                                            color: Week6Style.body,
                                          ),
                                        ),
                                      ),
                                    if (entry.movie?.posterPath == null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '포스터 정보 없음',
                                          style: Week6Style.text(
                                            13,
                                            18,
                                            color: Week6Style.body,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '등록일 ${rating.createdAt.toLocal().toIso8601String().split('T').first}',
                                      style: Week6Style.text(
                                        11,
                                        15,
                                        color: Week6Style.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            },
          ),
        ],
      ),
    ),
  );
}
