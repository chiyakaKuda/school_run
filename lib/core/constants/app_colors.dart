import 'package:flutter/material.dart';

/// Raw palette. Prefer reading colours from `Theme.of(context).colorScheme`
/// in widgets; these are the source values the theme is built from.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFFF5A623);
  static const Color primaryDark = Color(0xFFC97F04);
  static const Color secondary = Color(0xFF1F3A5F);

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1C1E);
  static const Color backgroundDark = Color(0xFF121316);

  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE2E5EA);

  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A33D);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF3B82F6);

  /// Trip / student status accents.
  static const Color onboard = success;
  static const Color waiting = warning;
  static const Color absent = textSecondary;
}
