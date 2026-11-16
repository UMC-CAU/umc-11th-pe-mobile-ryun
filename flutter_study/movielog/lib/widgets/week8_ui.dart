import 'package:flutter/material.dart';

import '../theme/week6_style.dart';

/// Shared presentation values from the workbook's 390 x 844 W8 frames.
abstract final class Week8Ui {
  static InputDecoration input({
    String? hint,
    String? error,
    bool readOnly = false,
  }) => InputDecoration(
    hintText: hint,
    errorText: error,
    isDense: true,
    filled: true,
    fillColor: readOnly ? const Color(0xFFF0EDF3) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: Week6Style.text(14, 20, color: Week6Style.hint),
    errorStyle: Week6Style.text(12, 18, color: const Color(0xFFBA1A1A)),
    errorMaxLines: 3,
    border: _border(Week6Style.border),
    enabledBorder: _border(Week6Style.border),
    disabledBorder: _border(Week6Style.border),
    focusedBorder: _border(Week6Style.primary, width: 1.5),
    errorBorder: _border(const Color(0xFFBA1A1A)),
    focusedErrorBorder: _border(const Color(0xFFBA1A1A), width: 1.5),
  );
  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
  static AppBar appBar(
    String title, {
    VoidCallback? onBack,
    List<Widget>? actions,
    bool centered = true,
  }) => AppBar(
    backgroundColor: Week6Style.background,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    toolbarHeight: 64,
    centerTitle: centered,
    titleSpacing: 16,
    title: Text(
      title,
      style: Week6Style.text(
        centered ? 20 : 22,
        centered ? 27 : 30,
        color: Week6Style.primary,
        weight: FontWeight.w700,
      ),
    ),
    leading: onBack == null
        ? null
        : IconButton(
            tooltip: '뒤로가기',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 24, color: Week6Style.ink),
          ),
    actions: actions,
  );
}

class Week8Field extends StatelessWidget {
  const Week8Field({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.characterLimit,
  });
  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final String? hint, error;
  final bool enabled, readOnly, obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted, onChanged;
  final int? characterLimit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: Week6Style.text(
          14,
          20,
          color: Week6Style.body,
          weight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        key: fieldKey,
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        enableSuggestions: !obscureText,
        autocorrect: !obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textInputAction: obscureText
            ? TextInputAction.done
            : TextInputAction.next,
        style: Week6Style.text(
          14,
          20,
          color: readOnly ? Week6Style.hint : Week6Style.ink,
        ),
        decoration: Week8Ui.input(hint: hint, error: error, readOnly: readOnly),
      ),
      if (characterLimit != null) ...[
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) => Text(
            '${value.text.characters.length} / $characterLimit',
            textAlign: TextAlign.right,
            style: Week6Style.text(
              11,
              16,
              color: value.text.characters.length > characterLimit!
                  ? const Color(0xFFBA1A1A)
                  : Week6Style.hint,
            ),
          ),
        ),
      ],
    ],
  );
}
