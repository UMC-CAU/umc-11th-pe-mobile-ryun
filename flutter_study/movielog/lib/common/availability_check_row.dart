import 'package:flutter/material.dart';

class AvailabilityCheckRow extends StatelessWidget {
  const AvailabilityCheckRow({
    super.key,
    required this.label,
    required this.onPressed,
    required this.busy,
    this.message,
    this.available,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? message;
  final bool? available;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: busy ? null : onPressed,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined, size: 18),
            label: Text(busy ? '확인 중...' : '$label 중복 확인'),
          ),
        ),
        if (message != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message!,
                style: TextStyle(
                  fontSize: 13,
                  color: available == true
                      ? const Color(0xFF087044)
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
