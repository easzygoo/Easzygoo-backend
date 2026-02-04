import 'package:flutter/material.dart';

/// EaszyGoo Rider brand colors + commonly used UI tokens.
///
/// Keep this file as the single source of truth for color values.
/// ThemeData and widgets should reference these constants (not raw hex).
class AppColors {
  AppColors._();

  // Brand
  static const Color primaryBlue = Color(0xFF1E4DB7);
  static const Color primaryDarkBlue = Color(0xFF153B8E);
  static const Color accentYellow = Color(0xFFFFD600);

  // Status
  static const Color freshGreen = Color(0xFF4CAF50);
  static const Color softRed = Color(0xFFE53935);

  // Neutrals
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  // UI tokens
  static const Color border = Color(0xFFE5E7EB); // neutral-200
  static const Color shadow = Color(0x14000000); // 8% black

  // Header / emphasis surfaces (used for the bright yellow top sections)
  static const Color headerYellow = accentYellow;
  static const Color headerOnYellow = textPrimary;

  // Buttons
  static const Color buttonPrimary = primaryBlue;
  static const Color buttonOnPrimary = Colors.white;

  static const Color buttonSuccess = freshGreen;
  static const Color buttonOnSuccess = Colors.white;

  static const Color buttonDanger = softRed;
  static const Color buttonOnDanger = Colors.white;

  /// Material 3 ColorScheme tuned for the Rider app.
  ///
  /// We intentionally set `primary` to brand blue and `secondary` to accent
  /// yellow to match the reference design’s strong yellow headers.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,

    primary: primaryBlue,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDCE7FF),
    onPrimaryContainer: textPrimary,

    secondary: accentYellow,
    onSecondary: textPrimary,
    secondaryContainer: Color(0xFFFFF3B0),
    onSecondaryContainer: textPrimary,

    tertiary: freshGreen,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFCDEECD),
    onTertiaryContainer: textPrimary,

    error: softRed,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: textPrimary,

    surface: surfaceWhite,
    onSurface: textPrimary,

    surfaceContainerHighest: Color(0xFFF3F4F6),

    outline: border,
    outlineVariant: Color(0xFFD1D5DB),

    shadow: shadow,
    scrim: Color(0x66000000),

    inverseSurface: Color(0xFF111827),
    onInverseSurface: Color(0xFFF9FAFB),
    inversePrimary: Color(0xFF9DB7FF),

    surfaceTint: primaryBlue,
  );
}
