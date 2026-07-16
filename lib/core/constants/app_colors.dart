import 'package:flutter/material.dart';

/// Raw palette, dark-first. Prefer reading colours from
/// `Theme.of(context).colorScheme` in widgets; these are the source values the
/// theme is built from.
class AppColors {
  const AppColors._();

  /// The single accent. Used sparingly: the primary action on a screen, the
  /// selected state, and live/active indicators — nothing else.
  static const Color accent = Color(0xFF00E85C);
  static const Color onAccent = Color(0xFF06110A);

  /// Muted green fill for a selected card sitting on [surface].
  static const Color accentContainer = Color(0xFF0E3B21);
  static const Color onAccentContainer = Color(0xFF8CF5B6);

  static const Color background = Color(0xFF0A0B0D);
  static const Color surface = Color(0xFF17181C);
  static const Color surfaceVariant = Color(0xFF212329);
  static const Color outline = Color(0xFF2E3138);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9BA1AC);

  static const Color success = accent;
  static const Color warning = Color(0xFFFFC24B);
  static const Color error = Color(0xFFFF5A5A);
  static const Color info = Color(0xFF4C9AFF);

  /// Trip / student status accents.
  static const Color onboard = accent;
  static const Color waiting = warning;
  static const Color absent = textSecondary;
}

/// Corner radii, so cards, sheets and pills stay consistent across screens.
class AppRadius {
  const AppRadius._();

  static const double input = 16;
  static const double card = 24;
  static const double sheet = 28;

  /// Fully rounded — pills and circular icon buttons.
  static const double pill = 999;
}
