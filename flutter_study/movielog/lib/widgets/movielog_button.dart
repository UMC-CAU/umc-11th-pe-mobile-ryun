import 'package:flutter/material.dart';

import '../theme/week6_style.dart';

class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.disabledColor = Week6Style.loading,
    this.fontSize = 13,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final Color disabledColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 44,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Week6Style.primary,
        disabledBackgroundColor: isLoading ? Week6Style.loading : disabledColor,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(102, 44),
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        textStyle: Week6Style.text(
          fontSize,
          fontSize + 5,
          weight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    ),
  );
}
