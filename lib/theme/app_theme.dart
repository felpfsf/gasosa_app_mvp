import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        outline: AppColors.border,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.titleLg,
        headlineMedium: AppTypography.titleMd,
        headlineSmall: AppTypography.titleSm,
        titleLarge: AppTypography.textLgBold,
        titleMedium: AppTypography.textMdBold,
        titleSmall: AppTypography.textSmBold,
        bodyLarge: AppTypography.textMdRegular,
        bodyMedium: AppTypography.textSmMedium,
        bodySmall: AppTypography.textSmRegular,
        labelLarge: AppTypography.textSmBold,
        labelMedium: AppTypography.textSmMedium,
        labelSmall: AppTypography.textSmRegular,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        hintStyle: AppTypography.textSmRegular.copyWith(
          color: AppColors.text.withValues(alpha: .6),
        ),
        errorStyle: AppTypography.textSmRegular.copyWith(color: AppColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.text,
          textStyle: AppTypography.textSmBold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}
