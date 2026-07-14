import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF0066B4);
  static const Color primaryBlueDark = Color(0xFF004A8A);
  static const Color primaryBlueLight = Color(0xFF3399E8);

  // Secondary Colors
  static const Color secondaryTeal = Color(0xFF00A896);
  static const Color secondaryTealDark = Color(0xFF007B6B);
  static const Color secondaryTealLight = Color(0xFF33C9B3);

  // Accent Colors
  static const Color accentOrange = Color(0xFFFF7F50);
  static const Color accentOrangeDark = Color(0xFFE65C2B);
  static const Color accentOrangeLight = Color(0xFFFFAA7A);

  // Semantic Colors
  static const Color successGreen = Color(0xFF2E8B57);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color infoBlue = Color(0xFF3498DB);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Cream palette — a warm, off-white surface that resembles paper /
  // parchment. Used by the cream theme as the scaffold background and
  // card surface so the app reads as soft and easy on the eyes.
  static const Color cream50 = Color(0xFFFBF7F0);
  static const Color cream100 = Color(0xFFF6EFE0);
  static const Color cream200 = Color(0xFFEFE5CE);
  static const Color cream300 = Color(0xFFE5D7B5);
  static const Color creamShadow = Color(0xFFD4BC83);
  static const Color creamTextPrimary = Color(0xFF3B2A14);
  static const Color creamTextSecondary = Color(0xFF6B5430);

  // Dark-mode neutrals. Slightly warmer than pure #212121 to feel
  // more "coastal" than sterile.
  static const Color dark900 = Color(0xFF0F172A);
  static const Color dark800 = Color(0xFF1E293B);
  static const Color dark700 = Color(0xFF334155);
  static const Color dark600 = Color(0xFF475569);
  static const Color dark500 = Color(0xFF64748B);
  static const Color dark400 = Color(0xFF94A3B8);
  static const Color dark300 = Color(0xFFCBD5E1);
  static const Color dark200 = Color(0xFFE2E8F0);
  static const Color dark100 = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Status Colors
  static const Color pending = Color(0xFFFFC107);
  static const Color active = Color(0xFF4CAF50);
  static const Color inactive = Color(0xFF9E9E9E);
  static const Color completed = Color(0xFF2E8B57);
  static const Color cancelled = Color(0xFFE74C3C);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, secondaryTeal],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentOrange, primaryBlue],
  );
}

/// The three theming modes the user can pick from. Persisted in
/// SharedPreferences (under [kThemeModePrefKey]) so the choice
/// survives app restarts and account switches.
enum AppThemeMode {
  /// Classic white surfaces — ideal for daylight, strong contrast.
  light,

  /// Warm cream tones — soft on the eyes, premium/paper feel.
  cream,

  /// Dark navy + slate — easy on the eyes in low light.
  dark;

  /// Pretty-printed label.
  String get label => switch (this) {
        AppThemeMode.light => 'White',
        AppThemeMode.cream => 'Cream',
        AppThemeMode.dark => 'Dark',
      };

  /// Short subtitle shown beneath the label in the switcher.
  String get subtitle => switch (this) {
        AppThemeMode.light => 'Pure white, maximum contrast',
        AppThemeMode.cream => 'Warm, soft on the eyes',
        AppThemeMode.dark => 'Dark slate, low light friendly',
      };

  /// Storage key for SharedPreferences. The value is the
  /// [AppThemeMode.name] (e.g. `"cream"`).
  static const String prefKey = 'app.themeMode.v1';
}

/// A flat, immutable snapshot of every color token a widget might
/// read from the active theme. Use this when a widget cannot rely on
/// `Theme.of(context)` (e.g. `BitmapDescriptor` markers, `Canvas`
/// drawing, custom shape painters). The [AppThemeController]
/// produces one of these for the active mode and exposes it via the
/// `themeTokensProvider` Riverpod provider.
class AppColorTokens {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color accent;
  final Color accentMuted;
  final Color success;
  final Color warning;
  final Color error;
  final Color shadow;

  const AppColorTokens({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.accent,
    required this.accentMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.shadow,
  });

  /// Light tokens. Pure-white surfaces, navy text.
  static const AppColorTokens light = AppColorTokens(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF5F5F5),
    border: Color(0xFFEEEEEE),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textHint: Color(0xFF9E9E9E),
    accent: Color(0xFF0066B4),
    accentMuted: Color(0xFF3399E8),
    success: Color(0xFF2E8B57),
    warning: Color(0xFFFFC107),
    error: Color(0xFFE74C3C),
    shadow: Color(0xFF000000),
  );

  /// Cream tokens. Warm off-white surfaces, deep brown text — like
  /// reading a paper almanac.
  static const AppColorTokens cream = AppColorTokens(
    brightness: Brightness.light,
    background: Color(0xFFFBF7F0),
    surface: Color(0xFFFFF8E8),
    surfaceAlt: Color(0xFFF6EFE0),
    border: Color(0xFFE5D7B5),
    textPrimary: Color(0xFF3B2A14),
    textSecondary: Color(0xFF6B5430),
    textHint: Color(0xFF9C8554),
    accent: Color(0xFFB45309),
    accentMuted: Color(0xFFD4BC83),
    success: Color(0xFF2E8B57),
    warning: Color(0xFFB45309),
    error: Color(0xFFB91C1C),
    shadow: Color(0xFFD4BC83),
  );

  /// Dark tokens. Navy / slate surfaces, soft off-white text.
  static const AppColorTokens dark = AppColorTokens(
    brightness: Brightness.dark,
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceAlt: Color(0xFF334155),
    border: Color(0xFF334155),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFFCBD5E1),
    textHint: Color(0xFF94A3B8),
    accent: Color(0xFF3399E8),
    accentMuted: Color(0xFF1D4ED8),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    shadow: Color(0xFF000000),
  );

  /// Lookup by mode.
  static AppColorTokens of(AppThemeMode mode) => switch (mode) {
        AppThemeMode.light => light,
        AppThemeMode.cream => cream,
        AppThemeMode.dark => dark,
      };
}
