import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Dark-only theme built from [AppColors].
///
/// Outfit and Inter ship as variable fonts, so a weight is only applied when a
/// `wght` [FontVariation] is set — [_display] and [_body] handle that. Setting
/// `fontWeight` alone would silently render everything at 400.
class AppTheme {
  const AppTheme._();

  static const String displayFamily = 'Outfit';
  static const String bodyFamily = 'Inter';

  /// Outfit — big headings only. Tight tracking, heavy weights.
  static TextStyle _display({
    required double size,
    double weight = 700,
    double height = 1.08,
    double tracking = -0.5,
  }) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        height: height,
        letterSpacing: tracking,
        fontWeight: _toFontWeight(weight),
        fontVariations: [FontVariation('wght', weight)],
      );

  /// Inter — everything else.
  static TextStyle _body({
    required double size,
    double weight = 400,
    double height = 1.4,
    double tracking = 0,
  }) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontSize: size,
        height: height,
        letterSpacing: tracking,
        fontWeight: _toFontWeight(weight),
        fontVariations: [FontVariation('wght', weight)],
      );

  static FontWeight _toFontWeight(double weight) =>
      FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)];

  static const ColorScheme _scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    primaryContainer: AppColors.accentContainer,
    onPrimaryContainer: AppColors.onAccentContainer,
    secondary: AppColors.accent,
    onSecondary: AppColors.onAccent,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.outline,
    outlineVariant: AppColors.outline,
    error: AppColors.error,
    onError: Colors.white,
  );

  static TextTheme get textTheme => TextTheme(
        displayLarge: _display(size: 52, tracking: -1.4),
        displayMedium: _display(size: 44, tracking: -1.2),
        displaySmall: _display(size: 36, tracking: -1),
        headlineLarge: _display(size: 32, tracking: -0.8),
        headlineMedium: _display(size: 28, tracking: -0.6),
        headlineSmall: _display(size: 24, tracking: -0.4),
        titleLarge: _display(size: 20, weight: 600, height: 1.2, tracking: -0.2),
        titleMedium: _body(size: 16, weight: 600, height: 1.25),
        titleSmall: _body(size: 14, weight: 600, height: 1.25),
        bodyLarge: _body(size: 16),
        bodyMedium: _body(size: 14),
        bodySmall: _body(size: 12, height: 1.35),
        labelLarge: _body(size: 14, weight: 600, tracking: 0.1),
        labelMedium: _body(size: 12, weight: 600, tracking: 0.1),
        labelSmall: _body(size: 11, weight: 500, tracking: 0.2),
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: _scheme,
      fontFamily: bodyFamily,
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(AppColors.accent, width: 1.5),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.5),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceVariant,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: _body(size: 16, weight: 600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(58),
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: _body(size: 16, weight: 600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: _body(size: 14, weight: 600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.square(48),
          shape: const CircleBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        side: BorderSide.none,
        labelStyle: _body(size: 12, weight: 600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: _body(size: 14).copyWith(
          color: AppColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: color, width: width),
      );
}
