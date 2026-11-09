int validateServerScore(double value) {
  if (!value.isFinite ||
      value < 1 ||
      value > 5 ||
      value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });
  final int movieId;
  final int score;
  final String? comment;
  Map<String, dynamic> toJson() {
    validateServerScore(score.toDouble());
    if (movieId < 1) throw ArgumentError('영화 ID가 올바르지 않습니다.');
    if ((comment?.trim().length ?? 0) > 500) {
      throw ArgumentError('코멘트는 500자 이하로 입력해 주세요.');
    }
    return {
      'movieId': movieId,
      'score': score,
      if (comment?.trim().isNotEmpty ?? false) 'comment': comment!.trim(),
    };
  }
}
