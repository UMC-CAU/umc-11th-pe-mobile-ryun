import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../common/movie_rating_input.dart';
import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _comment = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _score < 1) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final text = _comment.text.trim();
      if (text.length > 500) throw ArgumentError('코멘트는 500자 이하로 입력해 주세요.');
      await widget.onSubmit(_score, text.isEmpty ? null : text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final message = error is DioException
          ? writeErrorMessage(error)
          : error is StateError
          ? error.message.toString()
          : '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      setState(() {
        _saving = false;
        _error = message;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.initialScore > 0 ? '평점을 수정해주세요' : '평점을 남겨주세요'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MovieRatingInput(
              rating: _score.toDouble(),
              allowHalfRating: false,
              enabled: !_saving,
              onChanged: (value) =>
                  setState(() => _score = validateServerScore(value)),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('ratingCommentField'),
              controller: _comment,
              enabled: !_saving,
              maxLength: 500,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _saving ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          key: const Key('ratingConfirmButton'),
          label: '확인',
          isLoading: _saving,
          onPressed: _score > 0 && !_saving ? _save : null,
        ),
      ],
    ),
  );
}
