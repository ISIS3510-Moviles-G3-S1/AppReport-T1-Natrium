import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// UniMarket brand colors matching the web app index.css palette.
class AppTheme {
  // Base tokens from index.css (HSL converted to hex)
  static const Color black = Color(0xFF000000); // --primary
  static const Color gray = Color(0xFFBFBFBF); // --gray
  static const Color white = Color(0xFFFFFFFF); // --white / --card / --background

  // Brand / semantic colors
  static const Color deepGreen = Color(0xFF7C9885); // --sage-green / navbar-bg family
  static const Color sage = Color(0xFFB5B682); // --dry-sage (primary CTA bg)
  static const Color sageDark = Color(0xFF2B2B2B); // --foreground / charcoal
  static const Color mustard = Color(0xFFD4A84B); // rating stars (not in tokens but used on web)
  static const Color accent = Color(0xFFB5B682); // --cta / dry-sage
  static const Color warmBeige = Color(0xFFFEDC97);
  static const Color cardBg = white;
  static const Color background = white;

  // Supporting tokens
  static const Color muted = Color(0xFF6A8374); // approx --muted (147 10% 48%)
  static const Color mutedForeground = Color(0xFF1F5A73); // approx --muted-foreground (189 46% 28%)
  static const Color foreground = Color(0xFF2B2B2B); // --foreground / charcoal
  static const Color destructive = Color(0xFFDC2626);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: black,
          onPrimary: white,
          secondary: sage,
          onSecondary: sageDark,
          surface: cardBg,
          onSurface: foreground,
          error: destructive,
          onError: white,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: deepGreen,
          foregroundColor: white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: cardBg,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: sage,
            foregroundColor: sageDark,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: white,
            side: const BorderSide(color: Colors.white54),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: GoogleFonts.manropeTextTheme(
          ThemeData.light().textTheme,
        ).copyWith(
          // Override headings with Poppins
          displayLarge: GoogleFonts.poppins(
            fontSize: 57,
            fontWeight: FontWeight.w400,
            color: foreground,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 45,
            fontWeight: FontWeight.w400,
            color: foreground,
          ),
          displaySmall: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: foreground,
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      );
}
