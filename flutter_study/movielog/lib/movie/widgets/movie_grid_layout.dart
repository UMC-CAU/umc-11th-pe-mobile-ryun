import 'package:flutter/material.dart';

// 실제 카드와 Skeleton 카드가 동일한 열 수와 간격을 사용한다.
abstract final class MovieGridLayout {
  static const padding = EdgeInsets.fromLTRB(16, 16, 16, 32);

  static SliverGridDelegateWithFixedCrossAxisCount delegate(double width) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: width >= 900 ? 5 : (width >= 600 ? 3 : 2),
      crossAxisSpacing: 12,
      mainAxisSpacing: 20,
      childAspectRatio: 0.58,
    );
  }
}
