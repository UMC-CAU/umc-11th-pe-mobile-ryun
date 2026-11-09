import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.itemSize = 40,
    this.enabled = true,
    this.allowHalfRating = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final double itemSize;
  final bool enabled;
  final bool allowHalfRating;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: allowHalfRating ? 0.5 : 1,
      allowHalfRating: allowHalfRating,
      ignoreGestures: !enabled,
      itemCount: 5,
      itemSize: itemSize,
      itemBuilder: (context, index) =>
          const Icon(Icons.star, color: AppColors.primary),
      onRatingUpdate: onChanged,
    );
  }
}
