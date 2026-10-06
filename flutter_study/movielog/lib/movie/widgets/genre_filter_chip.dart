import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class GenreFilterChip extends StatelessWidget {
  const GenreFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      backgroundColor: AppColors.genreChipBackground,
      selectedColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.bodyText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 4 / 3,
      ),
      // 기본 글자 배율에서 보이는 높이 32px, 좌우 여백 16px.
      padding: const EdgeInsets.symmetric(vertical: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.standard,
      // 작은 Chip도 실제 터치 영역은 높이 48px을 확보한다.
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
