// Centralised palette for the Samaki Fresh Connect app.
//
// Theme inspired by the ocean/seafood identity:
// ● Light mode : Pure white background, Ocean Blue primary (#0284C7 → #0EA5E9),
//   wavy blue gradient header, clean cards.
// ● Dark mode  : Deep Navy (#0D1B2A) background, Midnight Navy cards (#132337),
//   same blue accents glowing against the dark.
//
// ALL COLOURS ARE BLUE. No green, no red, no yellow.

import 'package:flutter/material.dart';

class AppColors {
  // ── Brand: Ocean Blue ─────────────────────────────────────────────────────
  static const Color primaryTeal      = Color(0xFF0284C7);   // sky-600 — main blue
  static const Color primaryTealDark  = Color(0xFF0369A1);   // sky-700
  static const Color primaryTealLight = Color(0xFF0EA5E9);   // sky-500
  static const Color primaryCyan      = Color(0xFF0EA5E9);   // sky-500 — gradient end
  static const Color primaryCyanDark  = Color(0xFF0284C7);   // sky-600
  static const Color primaryCyanLight = Color(0xFF38BDF8);   // sky-400

  // ── Accent: Deep Blue for CTAs ─────────────────────────────────────────────
  static const Color accentTeal       = Color(0xFF0369A1);   // sky-700
  static const Color accentTealDark   = Color(0xFF075985);   // sky-800
  static const Color accentTealLight  = Color(0xFF38BDF8);   // sky-400

  // ── Light mode neutrals ───────────────────────────────────────────────────
  static const Color lightBg          = Color(0xFFFFFFFF);   // pure white
  static const Color lightSurface     = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt  = Color(0xFFF0F9FF);   // sky-50 tinted
  static const Color lightCard        = Color(0xFFF8FBFF);   // very faint blue-white
  static const Color lightBorder      = Color(0xFFE0F2FE);   // sky-100
  static const Color lightDivider     = Color(0xFFBAE6FD);   // sky-200

  // ── Dark mode neutrals ────────────────────────────────────────────────────
  static const Color darkNavy900      = Color(0xFF0D1B2A);   // Deepest navy background
  static const Color darkNavy800      = Color(0xFF112236);   // Surface / card
  static const Color darkNavy700      = Color(0xFF132D4A);   // Slightly lighter card
  static const Color darkNavy600      = Color(0xFF1A3A5C);   // Elevated surface
  static const Color darkNavy500      = Color(0xFF1E4A6E);   // Border/divider
  static const Color darkBorder       = Color(0xFF1E3A55);   // Subtle border

  // ── Semantic colours (ALL BLUE FAMILY) ────────────────────────────────────
  // Success → Deep blue instead of green
  static const Color success          = Color(0xFF0369A1);   // sky-700
  // Warning → Medium blue instead of yellow/amber
  static const Color warning          = Color(0xFF0284C7);   // sky-600
  // Error → Darker navy blue instead of red
  static const Color errorRed         = Color(0xFF075985);   // sky-800
  static const Color info             = Color(0xFF0EA5E9);   // sky-500

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color white            = Color(0xFFFFFFFF);
  static const Color black            = Color(0xFF000000);

  // Light mode text
  static const Color textPrimary      = Color(0xFF0C1F2C);   // near-black navy
  static const Color textPrimaryLight = Color(0xFF0C1F2C);
  static const Color textSecondaryLight = Color(0xFF4B6B7A); // blue-gray
  static const Color textHintLight    = Color(0xFF94A3B8);

  // Dark mode text
  static const Color textPrimaryDark  = Color(0xFFECF4FF);   // off-white
  static const Color textSecondaryDark = Color(0xFFABC4D8);
  static const Color textHintDark     = Color(0xFF6A8FA8);

  // ── Backwards-compatible aliases ─────────────────────────────────────────
  static const Color primaryBlue        = primaryTeal;
  static const Color primaryBlueDark    = primaryTealDark;
  static const Color primaryBlueLight   = primaryTealLight;
  static const Color primaryBlueLightest = Color(0xFFE0F2FE);
  static const Color primaryBlueDarkest  = Color(0xFF0C3C5A);
  static const Color primaryBrightBlue  = primaryTealLight;
  static const Color primaryBrightBlueLight = Color(0xFF7DD3FC);
  // "Green" aliases now point to blue family
  static const Color accentGreen        = accentTeal;
  static const Color accentGreenDark    = accentTealDark;
  static const Color accentGreenLight   = accentTealLight;
  static const Color accentGreenLightest = Color(0xFFE0F2FE);   // sky-100
  static const Color accentGreenDarkest  = Color(0xFF0C3C5A);
  static const Color accentTealGreen    = accentTeal;
  static const Color accentTealGreenLight = accentTealLight;
  static const Color accentTealGreenDarkest = Color(0xFF075985);  // sky-800
  static const Color successGreen       = success;           // now deep blue
  static const Color infoBlue           = info;
  static const Color secondaryTeal      = accentTeal;
  static const Color accentOrange       = Color(0xFF0284C7); // was orange → now blue
  static const Color warningAmber       = Color(0xFF0284C7); // was amber → now blue
  static const Color textSecondary      = textSecondaryLight;

  // Grayscale ramp (all mapped to sky-blue family)
  static const Color gray50  = Color(0xFFF0F9FF);
  static const Color gray100 = Color(0xFFE0F2FE);
  static const Color gray200 = Color(0xFFBAE6FD);
  static const Color gray300 = Color(0xFF7DD3FC);
  static const Color gray400 = Color(0xFF38BDF8);
  static const Color gray500 = Color(0xFF0EA5E9);
  static const Color gray600 = Color(0xFF0284C7);
  static const Color gray700 = Color(0xFF0369A1);
  static const Color gray800 = Color(0xFF075985);
  static const Color gray900 = Color(0xFF0C4A6E);

  // Status — all blue family
  static const Color pending   = Color(0xFF0EA5E9);   // sky-500 (was amber)
  static const Color active    = Color(0xFF0284C7);   // sky-600 (was green)
  static const Color inactive  = Color(0xFF94A3B8);   // slate-400
  static const Color completed = Color(0xFF0369A1);   // sky-700 (was teal-green)
  static const Color cancelled = Color(0xFF1E3A55);   // dark navy (was red)

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryCyan],
  );

  static const LinearGradient oceanLightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTealLight, accentTeal],
  );

  static const LinearGradient deepNavyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
  );

  static const LinearGradient loginButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
  );

  static const LinearGradient primaryGradient = lightGradient;
  static const LinearGradient accentGradient  = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentTeal, primaryTeal],
  );
}

/// The two theming modes the user can pick from.
enum AppThemeMode {
  light,
  dark;

  String get label => switch (this) {
        AppThemeMode.light => 'Light',
        AppThemeMode.dark  => 'Dark',
      };

  String get subtitle => switch (this) {
        AppThemeMode.light => 'Clean white with Ocean Blue accents',
        AppThemeMode.dark  => 'Deep Navy & Blue, easy on the eyes',
      };

  static const String _prefKeyPrefix  = 'app.themeMode.v3';
  static const String prefKeyAnonymous = '$_prefKeyPrefix.guest';

  static String prefKeyFor(String uid) => '$_prefKeyPrefix.user.$uid';

  static AppThemeMode fromName(String? raw) {
    if (raw == null) return AppThemeMode.light;
    for (final mode in AppThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return AppThemeMode.light;
  }
}

/// A flat, immutable snapshot of every colour token a widget might
/// read from the active theme.
class AppColorTokens {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color primary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color shadow;
  final LinearGradient brandGradient;

  const AppColorTokens({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.primary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.shadow,
    required this.brandGradient,
  });

  /// Light tokens — Pure white background, Ocean Blue primary. ALL BLUE.
  static const AppColorTokens light = AppColorTokens(
    brightness:    Brightness.light,
    background:    Color(0xFFFFFFFF),
    surface:       Color(0xFFFFFFFF),
    surfaceAlt:    Color(0xFFF0F9FF),      // sky-50
    border:        Color(0xFFE0F2FE),      // sky-100
    textPrimary:   Color(0xFF0C1F2C),
    textSecondary: Color(0xFF4B6B7A),
    textHint:      Color(0xFF94A3B8),
    primary:       Color(0xFF0284C7),      // sky-600
    accent:        Color(0xFF0EA5E9),      // sky-500
    success:       Color(0xFF0369A1),      // sky-700 (deep blue = "success")
    warning:       Color(0xFF0284C7),      // sky-600 (blue = "warning")
    error:         Color(0xFF075985),      // sky-800 (dark blue = "error")
    shadow:        Color(0x0F0284C7),
    brandGradient: AppColors.lightGradient,
  );

  /// Dark tokens — Deep Navy background, Blue primary. ALL BLUE.
  static const AppColorTokens dark = AppColorTokens(
    brightness:    Brightness.dark,
    background:    Color(0xFF0D1B2A),
    surface:       Color(0xFF112236),
    surfaceAlt:    Color(0xFF132D4A),
    border:        Color(0xFF1E3A55),
    textPrimary:   Color(0xFFECF4FF),
    textSecondary: Color(0xFFABC4D8),
    textHint:      Color(0xFF6A8FA8),
    primary:       Color(0xFF38BDF8),      // sky-400 — bright on dark
    accent:        Color(0xFF7DD3FC),      // sky-300
    success:       Color(0xFF0EA5E9),      // sky-500 (was green)
    warning:       Color(0xFF38BDF8),      // sky-400 (was amber)
    error:         Color(0xFF7DD3FC),      // sky-300 (was red)
    shadow:        Color(0x33000000),
    brandGradient: AppColors.darkGradient,
  );

  static AppColorTokens of(AppThemeMode mode) => switch (mode) {
        AppThemeMode.light => light,
        AppThemeMode.dark  => dark,
      };
}