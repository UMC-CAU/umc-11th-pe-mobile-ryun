import 'package:flutter/material.dart';

import '../theme/week6_style.dart';

class MovieLogTextFormField extends StatefulWidget {
  const MovieLogTextFormField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    required this.showValidation,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.isPassword = false,
    this.showSuccessIcon = true,
  });

  final String? errorText;
  final Key fieldKey;
  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final bool showSuccessIcon;
  final FormFieldValidator<String> validator;
  final bool showValidation;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<MovieLogTextFormField> createState() => _MovieLogTextFormFieldState();
}

class _MovieLogTextFormFieldState extends State<MovieLogTextFormField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText ?? widget.validator(widget.controller.text);
    final isInvalid = widget.showValidation && error != null;
    final isValid = widget.controller.text.isNotEmpty && error == null;
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Week6Style.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 19 / 14,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.isPassword && _obscurePassword,
          enableSuggestions: !widget.isPassword,
          autocorrect: !widget.isPassword,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => widget.validator(value) ?? widget.errorText,
          forceErrorText: widget.errorText,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          style: const TextStyle(
            color: Week6Style.hint,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 19 / 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            errorText: widget.errorText,
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Week6Style.hint),
            filled: true,
            fillColor: isInvalid
                ? errorColor.withValues(alpha: 0.12)
                : Week6Style.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 44,
            ),
            suffixIcon: _buildSuffixIcon(
              isInvalid: isInvalid,
              isValid: isValid,
              errorColor: errorColor,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Week6Style.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Week6Style.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            errorStyle: TextStyle(
              color: errorColor,
              fontSize: 12,
              height: 16 / 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon({
    required bool isInvalid,
    required bool isValid,
    required Color errorColor,
  }) {
    if (widget.isPassword) {
      return IconButton(
        key: const Key('passwordVisibilityButton'),
        tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
        onPressed: () {
          setState(() => _obscurePassword = !_obscurePassword);
        },
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility,
          color: isInvalid ? errorColor : Week6Style.hint,
        ),
      );
    }

    if (isInvalid) return Icon(Icons.error_outline, color: errorColor);
    if (isValid && widget.showSuccessIcon) {
      return const Icon(
        Icons.check_circle,
        color: Week6Style.primary,
        size: 20,
      );
    }
    return null;
  }
}
