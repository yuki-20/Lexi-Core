/// LexiCore — Liquid Glass Theme (iOS 26 Style)
/// Authentic Apple-inspired design system with glass tokens,
/// specular highlights, prismatic effects, and fluid typography.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidGlassTheme {
  LiquidGlassTheme._();

  // ── Background ────────────────────────────────────────────────────
  // Rich, deep background with color so glass panels have content to blur
  static const bgGradientStart = Color(0xFF0D0D1A);
  static const bgGradientEnd = Color(0xFF1A0A2E);
  static const bgDeep = Color(0xFF0A0A12);

  // ── Ambient Orb Colors (blurred behind glass for depth) ──────────
  static const orbPurple = Color(0xFF7C4DFF);
  static const orbCyan = Color(0xFF00E5FF);
  static const orbPink = Color(0xFFFF6090);
  static const orbBlue = Color(0xFF2979FF);
  static const orbAmber = Color(0xFFFFAB40);

  // ── Glass Tokens (iOS 26 specification) ──────────────────────────
  static const glassFill = Color(0x1AFFFFFF);         // 10% white
  static const glassFillHover = Color(0x24FFFFFF);     // 14% white
  static const glassBorder = Color(0x30FFFFFF);        // 19% white
  static const glassBorderHover = Color(0x50FFFFFF);   // 31% white
  static const glassHighlight = Color(0x60FFFFFF);     // 38% white — specular
  static const glassInnerShadow = Color(0x08000000);   // subtle depth

  // ── Specular Border Gradient (iOS 26 light edge) ────────────────
  static const specularBorder = LinearGradient(
    colors: [
      Color(0x00FFFFFF),
      Color(0x50FFFFFF),
      Color(0x70FFFFFF),
      Color(0x50FFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.2, 0.5, 0.8, 1.0],
  );

  // ── Accent Colors ───────────────────────────────────────────────
  static const accentPrimary = Color(0xFF7C4DFF);     // Vivid purple
  static const accentSecondary = Color(0xFF00E5FF);    // Cyan
  static const accentTertiary = Color(0xFFFF6090);     // Pink/coral

  // ── Part-of-Speech Colors ───────────────────────────────────────
  static const posNoun = Color(0xFF448AFF);
  static const posVerb = Color(0xFF69F0AE);
  static const posAdj = Color(0xFFFFAB40);
  static const posAdv = Color(0xFFFF5252);
  static const posOther = Color(0xFF80DEEA);

  // ── Text Colors ────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xB3F0F0F5);     // 70%
  static const textMuted = Color(0x66F0F0F5);         // 40%

  // ── Glass Params ──────────────────────────────────────────────
  static const double glassBlur = 28.0;               // iOS 26 uses ~25-30
  static const double glassSaturation = 1.8;
  static const double borderRadius = 20.0;
  static const double borderRadiusSm = 14.0;
  static const double borderRadiusLg = 28.0;
  static const double borderRadiusPill = 50.0;

  // ── Typography (iOS 26 San Francisco inspired) ─────────────────

  static TextStyle get heading => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get headingSm => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.4,
  );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textMuted,
    letterSpacing: 0.5,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.8,
  );

  // ── Material Theme ─────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDeep,
    colorScheme: ColorScheme.dark(
      primary: accentPrimary,
      secondary: accentSecondary,
      surface: bgDeep,
    ),
    textTheme: TextTheme(
      headlineLarge: heading,
      headlineSmall: headingSm,
      bodyLarge: body,
      bodySmall: bodySmall,
      labelSmall: mono,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
  );

  // ── Helpers ──────────────────────────────────────────────────────

  /// Get POS color for a specific part of speech
  static Color posColor(String pos) {
    switch (pos.toLowerCase()) {
      case 'noun':
        return posNoun;
      case 'verb':
        return posVerb;
      case 'adjective':
      case 'adj':
        return posAdj;
      case 'adverb':
      case 'adv':
        return posAdv;
      default:
        return posOther;
    }
  }
}
