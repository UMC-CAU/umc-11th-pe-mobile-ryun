import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../common/movie_rating_input.dart';
import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import '../core/session/auth_session.dart';
import 'movielog_button.dart';
import 'week8_ui.dart';
import '../theme/week6_style.dart';

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
      if (error is DioException &&
          {'RATING409_1', 'MEMBER404_1'}.contains(errorCode(error))) {
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(writeErrorMessage(error))));
        return;
      }
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
    child: Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.initialScore > 0 ? '평점을 수정해주세요' : '평점을 남겨주세요',
                  textAlign: TextAlign.center,
                  style: Week6Style.text(20, 28, weight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Center(
                  child: MovieRatingInput(
                    rating: _score.toDouble(),
                    itemSize: 36,
                    allowHalfRating: false,
                    enabled: !_saving,
                    onChanged: (value) =>
                        setState(() => _score = validateServerScore(value)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '코멘트 (선택, 최대 500자)',
                  style: Week6Style.text(12, 18, color: Week6Style.body),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('ratingCommentField'),
                  controller: _comment,
                  enabled: !_saving,
                  maxLength: 500,
                  minLines: 4,
                  maxLines: 5,
                  style: Week6Style.text(13, 20, color: Week6Style.body),
                  decoration: Week8Ui.input(hint: '이 영화의 인상적인 장면은…').copyWith(
                    fillColor: const Color(0xFFFAF7FC),
                    counterText: '',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: Week6Style.text(
                      12,
                      18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF0EAF8),
                            foregroundColor: Week6Style.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context, false),
                          child: Text(
                            '취소',
                            style: Week6Style.text(
                              14,
                              20,
                              color: Week6Style.primary,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: MovieLogButton(
                        key: const Key('ratingConfirmButton'),
                        label: '확인',
                        borderRadius: 24,
                        disabledColor: Week6Style.disabled,
                        fontSize: 14,
                        isLoading: _saving,
                        onPressed: _score > 0 && !_saving ? _save : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
