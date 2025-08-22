import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  /// Small text style 14 - Regular
  static final textSmRegular = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  /// Small text style 14 - Medium
  static final textSmMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  /// Small text style 14 - Bold
  static final textSmBold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  /// Medium text style 16 - Regular
  static final textMdRegular = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  /// Medium text style 16 - Bold
  static final textMdBold = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  /// Large text style 18 - Regular
  static final textLgRegular = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  /// Large text style 18 - Bold
  static final textLgBold = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  /// Small title style 20 - Medium
  static final titleSm = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  /// Medium title style 24 - Bold
  static final titleMd = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  /// Large title style 28 - Bold
  static final titleLg = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );
}
