import 'package:flutter/material.dart';

/// Values exported from the three 390 × 844 workbook Figma frames.
abstract final class Week6Style {
  static const background = Color(0xFFFEFCF9);
  static const primary = Color(0xFF6750A4);
  static const ink = Color(0xFF25232A);
  static const body = Color(0xFF655F6C);
  static const hint = Color(0xFF8A8391);
  static const border = Color(0xFFD9D3E1);
  static const placeholder = Color(0xFFD8D2E0);
  static const statBorder = Color(0xFFE4DAF1);
  static const entryBorder = Color(0xFFD6C9E8);
  static const chip = Color(0xFFEADCFD);
  static const navigationIndicator = Color(0xFFEEE1FA);
  static const disabled = Color(0xFFD3C6E2);
  static const loading = Color(0xFF79747E);
  static const success = Color(0xFF2E7D32);
  static const checking = Color(0xFF1565C0);

  static TextStyle text(
    double size,
    double lineHeight, {
    Color color = ink,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    color: color,
    letterSpacing: 0,
  );
}
