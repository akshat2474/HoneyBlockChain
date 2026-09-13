import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const canvas    = Color(0xFF000000);
  static const surface   = Color(0xFF0A0A0A);
  static const card      = Color(0xFF111111);
  static const cardHover = Color(0xFF161616);
  static const inset     = Color(0xFF1A1A1A);
  static const border    = Color(0xFF222222);
  static const borderHi  = Color(0xFF333333);
  static const textPrimary   = Color(0xFFEDEDED);
  static const textSecondary = Color(0xFF999999);
  static const textMuted     = Color(0xFF666666);
  static const green = Color(0xFF22C55E);
  static const red   = Color(0xFFEF4444);
  static const blue  = Color(0xFF3B82F6);
}

abstract final class AppTextStyles {
  static TextStyle get heroTitle => GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700,
        height: 1.05, letterSpacing: -2.0);

  static TextStyle get pageTitle => GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600,
        height: 1.20, letterSpacing: -0.4);

  static TextStyle get sectionHeading => GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600,
        height: 1.30);

  static TextStyle get cardHeading => GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500,
        height: 1.35);

  static TextStyle get body => GoogleFonts.inter(
        color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w400,
        height: 1.55);

  static TextStyle get bodySmall => GoogleFonts.inter(
        color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w400,
        height: 1.45);

  static TextStyle get label => GoogleFonts.inter(
        color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500,
        height: 1.20, letterSpacing: 0.6);

  static TextStyle get mono => GoogleFonts.robotoMono(
        color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w400,
        height: 1.40);

  static TextStyle get stat => GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700,
        height: 1.05, letterSpacing: -1.0);

  static TextStyle get badge => GoogleFonts.inter(
        color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w400,
        height: 1.20, letterSpacing: 0.2);

  static TextStyle get brand => GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
        letterSpacing: -0.3);
}

abstract final class AppConstants {
  static const borderSide   = BorderSide(color: AppColors.border, width: 1);
  static const borderSideHi = BorderSide(color: AppColors.borderHi, width: 1);
  static const cardRadius   = BorderRadius.all(Radius.circular(6));
  static const smallRadius  = BorderRadius.all(Radius.circular(4));
  static const pillRadius   = BorderRadius.all(Radius.circular(100));
  static const double maxContentWidth   = 1100;
  static const double sectionSpacing    = 24;
  static const pagePadding = EdgeInsets.fromLTRB(24, 24, 24, 48);
}

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.textPrimary,
          secondary: AppColors.textSecondary,
          surface: AppColors.surface,
          error: AppColors.red,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        dividerColor: AppColors.border,
        dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inset,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: const OutlineInputBorder(borderRadius: AppConstants.smallRadius, borderSide: AppConstants.borderSide),
          enabledBorder: const OutlineInputBorder(borderRadius: AppConstants.smallRadius, borderSide: AppConstants.borderSide),
          focusedBorder: const OutlineInputBorder(borderRadius: AppConstants.smallRadius, borderSide: AppConstants.borderSideHi),
          labelStyle: AppTextStyles.label,
          hintStyle: AppTextStyles.bodySmall,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.card,
          contentTextStyle: AppTextStyles.body,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: AppConstants.smallRadius, side: AppConstants.borderSide),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 56,
          backgroundColor: AppColors.canvas,
          indicatorColor: AppColors.inset,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontSize: 10);
            }
            return AppTextStyles.label.copyWith(fontSize: 10);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.textPrimary, size: 20);
            }
            return const IconThemeData(color: AppColors.textMuted, size: 20);
          }),
        ),
      );
}
