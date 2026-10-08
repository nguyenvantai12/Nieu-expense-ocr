import 'package:flutter/material.dart';

/// App-wide Material 3 theme configuration.
/// Seed color: deep navy blue (#2C4570) — professional, trustworthy for finance.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF2C4570);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Roboto',
  );
}
