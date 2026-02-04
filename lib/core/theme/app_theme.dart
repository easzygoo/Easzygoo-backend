import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData light() {
    const scheme = AppColors.lightScheme;
    final textTheme = AppTextStyles.textTheme(
      primaryTextColor: scheme.onSurface,
      secondaryTextColor: AppColors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.headerYellow,
        foregroundColor: AppColors.headerOnYellow,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.headerOnYellow),
        iconTheme: const IconThemeData(color: AppColors.headerOnYellow),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: AppColors.accentYellow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return textTheme.labelMedium?.copyWith(
              color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? AppColors.primaryBlue : AppColors.textSecondary);
          },
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        shadowColor: scheme.shadow,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.softRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonOnPrimary,
          disabledBackgroundColor: AppColors.buttonPrimary.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: AppColors.accentYellow,
        disabledColor: scheme.surfaceContainerHighest,
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
