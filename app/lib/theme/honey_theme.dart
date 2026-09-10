import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color Palette — Vercel Dark + Honey Amber + Blockchain Blue
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Backgrounds
  static const canvas = Color(0xFF000000);
  static const surface = Color(0xFF0A0A0A);
  static const card = Color(0xFF111111);
  static const inset = Color(0xFF171717);

  // Borders
  static const border = Color(0xFF222222);
  static const borderLight = Color(0xFF333333);

  // Typography
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1A1);
  static const textMuted = Color(0xFF888888);

  // Accents
  static const amber = Color(0xFFF5A623);
  static const amberGlow = Color(0x33F5A623); // 20% opacity amber
  static const blue = Color(0xFF0070F3);
  static const blueGlow = Color(0x330070F3);

  // Status
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const greenGlow = Color(0x3310B981);
}

// ─────────────────────────────────────────────────────────────────────────────
// Text Styles
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  /// Massive hero headline — Space Grotesk bold
  static TextStyle get heroTitle => GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -1.5,
      );

  /// Page-level title — Space Grotesk semibold
  static TextStyle get pageTitle => GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.20,
        letterSpacing: -0.5,
      );

  /// Section heading — Inter semibold
  static TextStyle get sectionHeading => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.30,
        letterSpacing: -0.3,
      );

  /// Card heading — Inter semibold
  static TextStyle get cardHeading => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  /// Body text — Inter regular
  static TextStyle get body => GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.50,
      );

  /// Small body text
  static TextStyle get bodySmall => GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  /// Uppercase labels — Inter medium
  static TextStyle get label => GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.20,
        letterSpacing: 0.8,
      );

  /// Monospace for hashes, batch IDs, timestamps — JetBrains Mono
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.40,
      );

  /// Large stat numbers — JetBrains Mono bold
  static TextStyle get stat => GoogleFonts.jetBrainsMono(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.10,
      );

  /// Pill / badge text — Inter medium
  static TextStyle get badge => GoogleFonts.inter(
        color: AppColors.amber,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.20,
        letterSpacing: 0.3,
      );

  /// Navigation bar brand — Space Grotesk bold
  static TextStyle get brand => GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Constants
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppConstants {
  static const borderSide = BorderSide(color: AppColors.border, width: 1);
  static const cardRadius = BorderRadius.all(Radius.circular(8));
  static const smallRadius = BorderRadius.all(Radius.circular(6));
  static const pillRadius = BorderRadius.all(Radius.circular(100));
  static const double maxContentWidth = 1200;
  static const pagePadding = EdgeInsets.fromLTRB(16, 24, 16, 32);
}

// ─────────────────────────────────────────────────────────────────────────────
// ThemeData
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.textPrimary,
          secondary: AppColors.amber,
          surface: AppColors.surface,
          error: AppColors.red,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        dividerColor: AppColors.border,
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inset,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: const OutlineInputBorder(
            borderRadius: AppConstants.smallRadius,
            borderSide: AppConstants.borderSide,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppConstants.smallRadius,
            borderSide: AppConstants.borderSide,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppConstants.smallRadius,
            borderSide: BorderSide(color: AppColors.textPrimary),
          ),
          labelStyle: AppTextStyles.label,
          hintStyle: AppTextStyles.bodySmall,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.card,
          contentTextStyle: AppTextStyles.body,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: AppConstants.smallRadius,
            side: AppConstants.borderSide,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 64,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.inset,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.label
                  .copyWith(color: AppColors.textPrimary, fontSize: 10);
            }
            return AppTextStyles.label.copyWith(fontSize: 10);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                  color: AppColors.textPrimary, size: 22);
            }
            return const IconThemeData(color: AppColors.textMuted, size: 22);
          }),
        ),
      );
}
