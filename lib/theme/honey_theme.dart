import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class HoneyColors {
  static const gold = Color(0xFFF5A623);
  static const goldDark = Color(0xFFD98800);
  static const cream = Color(0xFFFFF3D6);
  static const offWhite = Color(0xFFFDF8EF);
  static const brown = Color(0xFF3B2F1E);
  static const muted = Color(0xFF8B7355);
  static const white = Colors.white;
  static const warning = Color(0xFFC94A36);
}

abstract final class HoneyTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: HoneyColors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: HoneyColors.gold,
          primary: HoneyColors.gold,
          surface: HoneyColors.white,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().apply(
          bodyColor: HoneyColors.brown,
          displayColor: HoneyColors.brown,
        ),
      );

  static TextStyle get logo => GoogleFonts.pacifico(
        color: HoneyColors.brown,
        fontSize: 27,
        fontWeight: FontWeight.w400,
      );

  static ButtonStyle get goldButton => ElevatedButton.styleFrom(
        backgroundColor: HoneyColors.gold,
        foregroundColor: HoneyColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
      );
}
