/// LexiCore — Liquid Glass Theme
/// Design tokens for the entire Liquid Glass aesthetic.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidGlassTheme {
  // ── Colors ──
  static const Color bgDark = Color(0xFF0A0A12);
  static const Color bgGradientStart = Color(0xFF0D0D1A);
  static const Color bgGradientEnd = Color(0xFF1A0A2E);

  static const Color glassFill = Color(0x18FFFFFF);
  static const Color glassBorder = Color(0x30FFFFFF);
  static const Color glassHighlight = Color(0x60FFFFFF);

  static const Color accentPrimary = Color(0xFF7C4DFF);
  static const Color accentSecondary = Color(0xFF00E5FF);
  static const Color accentTertiary = Color(0xFFFF6090);

  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xAAF0F0FF);
  static const Color textMuted = Color(0x66F0F0FF);

  // POS tag colors
  static const Color posNoun = Color(0xFF64B5F6);
  static const Color posVerb = Color(0xFF81C784);
  static const Color posAdj = Color(0xFFFFB74D);
  static const Color posAdv = Color(0xFFE57373);
  static const Color posOther = Color(0xFFCE93D8);

  static Color getPosColor(String pos) {
    switch (pos.toLowerCase()) {
      case 'noun': return posNoun;
      case 'verb': return posVerb;
      case 'adjective': return posAdj;
      case 'adverb': return posAdv;
      case 'interjection': return accentTertiary;
      default: return posOther;
    }
  }

  // ── Blur / Glass ──
  static const double glassBlur = 40.0;
  static const double glassSaturation = 1.8;
  static const double glassOpacity = 0.08;

  // ── Borders ──
  static const double borderRadius = 20.0;
  static const double borderRadiusSm = 12.0;
  static const double borderRadiusXs = 8.0;

  // ── Specular gradient (simulates light hitting glass edge) ──
  static const LinearGradient specularBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x50FFFFFF),
      Color(0x10FFFFFF),
      Color(0x05FFFFFF),
      Color(0x20FFFFFF),
    ],
  );

  // ── Typography ──
  static TextStyle get heading => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headingSm => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.6,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: accentSecondary,
  );

  static TextStyle get searchInput => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  // ── ThemeData ──
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: accentPrimary,
      secondary: accentSecondary,
      surface: bgDark,
    ),
    textTheme: TextTheme(
      headlineLarge: heading,
      headlineSmall: headingSm,
      bodyLarge: body,
      bodySmall: bodySmall,
      labelSmall: mono,
    ),
  );
}
