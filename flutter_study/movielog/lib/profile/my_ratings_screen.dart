import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../data/models/rating_dto.dart';
import '../data/services/rating_api_service.dart';
import '../view_models/learning_member_session.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/week6_app_bar.dart';
import '../theme/week6_style.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  final _selection = <int>{};
  bool _editing = false;
  bool _deletingSelection = false;

  Future<void> _confirmSelection(MyRatingsViewModel model) async {
    if (_selection.isEmpty || _deletingSelection || model.isWriting) return;
    final targets = {..._selection};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('선택한 ${targets.length}개의 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          MovieLogButton(
            label: '취소',
            onPressed: () => Navigator.pop(context, false),
          ),
          MovieLogButton(
            label: '삭제',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _deletingSelection = true);
    try {
      final failed = await model.deleteSelectedRatings(targets);
      if (!mounted) return;
      setState(() {
        _selection
          ..clear()
          ..addAll(failed);
        _editing = failed.isNotEmpty;
      });
      final deleted = targets.length - failed.length;
      final message = switch ((deleted, failed.length)) {
        (_, 0) => '$deleted개의 평점을 삭제했습니다.',
        (0, _) => '선택한 평점을 삭제하지 못했습니다. 다시 시도해 주세요.',
        _ => '$deleted개를 삭제했습니다. ${failed.length}개는 삭제하지 못했습니다.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _deletingSelection = false);
    }
  }

  Future<void> _edit(
    BuildContext context,
    MyRatingsViewModel model,
    RatingDto rating,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) => model.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (context.mounted && saved == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('평점을 수정했습니다.')));
    }
  }

  Future<void> _delete(
    BuildContext context,
    MyRatingsViewModel model,
    RatingDto rating,
  ) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteRatingDialog(
        onConfirm: () => model.deleteRating(rating.ratingId),
      ),
    );
    if (context.mounted && deleted == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('평점을 삭제했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MyRatingsViewModel>();
    final isOwner =
        context.watch<LearningMemberSession?>()?.memberId == model.memberId;
    return PopScope(
      canPop: !model.isWriting && !_deletingSelection,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            backgroundColor: Week6Style.background,
            appBar: Week6AppBar(
              title: '내가 등록한 평점',
              centerTitle: true,
              onBack: () {
                if (model.isWriting || _deletingSelection) return;
                context.canPop() ? context.pop() : context.go('/my');
              },
            ),
            bottomNavigationBar: _editing
                ? SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: MovieLogButton(
                        key: const Key('delete-selected-ratings'),
                        width: double.infinity,
                        label: '선택한 ${_selection.length}개 삭제',
                        onPressed: _selection.isEmpty || model.isWriting
                            ? null
                            : () => _confirmSelection(model),
                      ),
                    ),
                  )
                : null,
            body: Consumer<MyRatingsViewModel>(
              builder: (context, model, _) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editing
                              ? '${_selection.length}개 선택'
                              : '학습용 회원 ${model.memberId}의 평점',
                        ),
                        if (isOwner &&
                            model.status == MyRatingsLoadStatus.success)
                          TextButton(
                            onPressed: model.isWriting
                                ? null
                                : () => setState(() {
                                    _editing = !_editing;
                                    _selection.clear();
                                  }),
                            child: Text(_editing ? '취소' : '편집'),
                          ),
                      ],
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
                              Text(
                                model.refreshWarning ??
                                    model.message ??
                                    '목록을 불러오지 못했습니다.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              MovieLogButton(
                                label: model.refreshWarning == null
                                    ? '다시 시도'
                                    : '조회 다시 시도',
                                onPressed: model.isWriting ? null : model.load,
                              ),
                            ],
                          ),
                        ),
                      ),
                      MyRatingsLoadStatus.success => RefreshIndicator(
                        onRefresh: model.load,
                        notificationPredicate: (notification) =>
                            !_editing && notification.depth == 0,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: TmdbPosterImage(
                                          posterPath: entry.movie?.posterPath,
                                          width: 82,
                                          height: 124,
                                          placeholderColor:
                                              Week6Style.placeholder,
                                          showPlaceholderIcon: false,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                padding: const EdgeInsets.only(
                                                  top: 12,
                                                ),
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
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
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
                                      if (isOwner && _editing)
                                        Checkbox(
                                          key: ValueKey(
                                            'select-rating-${rating.ratingId}',
                                          ),
                                          semanticLabel:
                                              '${entry.movie?.title ?? rating.movieId} 평점 선택',
                                          value: _selection.contains(
                                            rating.ratingId,
                                          ),
                                          onChanged: model.isWriting
                                              ? null
                                              : (selected) => setState(() {
                                                  if (selected == true) {
                                                    _selection.add(
                                                      rating.ratingId,
                                                    );
                                                  } else {
                                                    _selection.remove(
                                                      rating.ratingId,
                                                    );
                                                  }
                                                }),
                                        )
                                      else if (isOwner)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              onPressed: model.isWriting
                                                  ? null
                                                  : () => _edit(
                                                      context,
                                                      model,
                                                      rating,
                                                    ),
                                              child: const Text('수정'),
                                            ),
                                            TextButton(
                                              onPressed: model.isWriting
                                                  ? null
                                                  : () => _delete(
                                                      context,
                                                      model,
                                                      rating,
                                                    ),
                                              child: const Text('삭제'),
                                            ),
                                          ],
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
          ),
          if (_deletingSelection) ...[
            const ModalBarrier(dismissible: false, color: Colors.black45),
            const Center(
              child: CircularProgressIndicator(
                key: Key('delete-selection-progress'),
                color: Colors.white,
                semanticsLabel: '선택한 평점 삭제 중',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});
  final Future<void> Function() onConfirm;
  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _deleting = false;
  String? _error;
  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = error is DioException
            ? writeErrorMessage(error)
            : '삭제 결과를 확인하지 못했습니다. 목록을 다시 확인해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Text(_error ?? '삭제한 평점은 복구할 수 없습니다.'),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          label: '삭제',
          isLoading: _deleting,
          onPressed: _deleting ? null : _delete,
        ),
      ],
    ),
  );
}
