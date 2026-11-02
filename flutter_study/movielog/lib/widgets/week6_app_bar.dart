import 'package:flutter/material.dart';

import '../theme/week6_style.dart';

class Week6AppBar extends StatelessWidget implements PreferredSizeWidget {
  const Week6AppBar({
    super.key,
    required this.title,
    this.onBack,
    this.centerTitle = true,
  });
  final String title;
  final VoidCallback? onBack;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Week6Style.background,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    toolbarHeight: 64,
    titleSpacing: 16,
    centerTitle: centerTitle,
    title: Text(
      title,
      style: Week6Style.text(
        centerTitle ? 20 : 22,
        centerTitle ? 27 : 30,
        color: Week6Style.primary,
        weight: FontWeight.w700,
      ),
    ),
    leading: onBack == null
        ? null
        : IconButton(
            tooltip: '뒤로가기',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Week6Style.ink, size: 24),
          ),
  );

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
