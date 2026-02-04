import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized typography for EaszyGoo Rider.
///
/// Goals:
/// - Strong readability for outdoor use
/// - Clear hierarchy (headers / labels / body)
/// - Consistent weights and line heights
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Roboto';

  /// Build a TextTheme for the app.
  ///
  /// We start from Material defaults and then apply size/weight/height tuning.
  static TextTheme textTheme({Color? primaryTextColor, Color? secondaryTextColor}) {
    final onSurface = primaryTextColor ?? AppColors.textPrimary;
    final secondary = secondaryTextColor ?? AppColors.textSecondary;

    // Material 3 naming: display/headline/title/body/label.
    return const TextTheme().copyWith(
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
      decorationColor: onSurface,
    ).copyWith(
      // Set secondary text tones.
      bodySmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ).copyWith(color: secondary),
      labelSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ).copyWith(color: secondary),
    );
  }
}
