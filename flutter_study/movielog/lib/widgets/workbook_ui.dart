import 'package:flutter/material.dart';

import '../theme/week6_style.dart';

InputDecoration workbookInput({
  String? hint,
  String? error,
  bool filled = false,
  Widget? suffix,
}) => InputDecoration(
  hintText: hint,
  errorText: error,
  suffixIcon: suffix,
  filled: true,
  fillColor: filled ? const Color(0xFFF0EDF3) : Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  hintStyle: Week6Style.text(14, 20, color: Week6Style.body),
  errorStyle: Week6Style.text(12, 18, color: const Color(0xFFBA1A1A)),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Week6Style.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Week6Style.border),
  ),
  disabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Week6Style.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Week6Style.primary, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
  ),
);

class WorkbookStateBody extends StatelessWidget {
  const WorkbookStateBody({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
    this.icon,
  });
  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: Week6Style.primary),
            const SizedBox(height: 32),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: Week6Style.text(
              16,
              24,
              color: Week6Style.body,
              weight: FontWeight.w700,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 12),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: Week6Style.text(14, 22, color: Week6Style.body),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: 218,
              height: 44,
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
