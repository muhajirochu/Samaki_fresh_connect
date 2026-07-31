// Centralised palette for the Samaki Fresh Connect app.
//
// The app supports exactly two themes — Light and Dark — defined by
// [AppColorTokens.light] and [AppColorTokens.dark]. Both share the same
// semantic keys so widgets can switch between themes without any code
// change; they only need to read tokens via
// `Theme.of(context).colorScheme`, `Theme.of(context).extension<BackgroundStyle>()`
// or `AppColorTokens.of(...)`.
//
// All other raw colour values live below as static constants for
// backwards compatibility with existing widgets. New code should
// prefer the token indirection so it works in both themes.

import 'package:flutter/material.dart';

class AppColors {
  // ── Brand: Light theme ─────────────────────────────────────────────────────
  // Modern Blue primary, Elegant Green accent — clean and premium.
  // Picked from the official Tailwind CSS palette so the brand
  // identity carries over to marketing surfaces.
  static const Color primaryBlue = Color(0xFF2563EB);          // Modern Blue (blue-600)
  static const Color primaryBlueDark = Color(0xFF1D4ED8);      // blue-700
  static const Color primaryBlueLight = Color(0xFF60A5FA);     // blue-400
  static const Color primaryBlueLightest = Color(0xFFDBE7FF);  // blue-100
  static const Color primaryBlueDarkest = Color(0xFF0B2B6B);   // blue-950

  static const Color accentGreen = Color(0xFF16A34A);          // Elegant Green (green-600)
  static const Color accentGreenDark = Color(0xFF15803D);      // green-700
  static const Color accentGreenLight = Color(0xFF4ADE80);     // green-400
  static const Color accentGreenLightest = Color(0xFFD1FAE5);  // green-100
  static const Color accentGreenDarkest = Color(0xFF064E3B);   // green-900

  // ── Brand: Dark theme ──────────────────────────────────────────────────────
  // Bright Blue primary, Teal Green accent — deep-navy enterprise feel.
  static const Color primaryBrightBlue = Color(0xFF3B82F6);    // blue-500
  static const Color primaryBrightBlueLight = Color(0xFF60A5FA);
  static const Color accentTealGreen = Color(0xFF14B8A6);      // teal-500
  static const Color accentTealGreenLight = Color(0xFF2DD4BF);  // teal-400
  static const Color accentTealGreenDarkest = Color(0xFF115E59); // teal-800

  // ── Material 3 ColorScheme.fromSeed() reference values ────────────────────
  // Use these with `ColorScheme.fromSeed(seedColor: ..., brightness: ...)`
  // to auto-derive a full Material 3 tonal palette (primary,
  // primaryContainer, onPrimaryContainer, surface tints, etc).
  static const Color lightSeedColor = primaryBlue;   // blue-600
  static const Color darkSeedColor = primaryBrightBlue;  // blue-500
  static const Color lightSecondarySeed = accentGreen;  // green-600
  static const Color darkSecondarySeed = accentTealGreen;  // teal-500

  // ── Dark-mode neutrals (Deep Navy + Blue-Gray) ─────────────────────────────
  // Deliberately not pure black — the deepest surface is a deep navy
  // and cards sit one step lighter as a blue-gray.
  static const Color darkNavy900 = Color(0xFF0B1220);          // Main background
  static const Color darkNavy800 = Color(0xFF111A2E);          // Surface / card
  static const Color darkBlueGray700 = Color(0xFF1B2640);      // Card / container
  static const Color darkBlueGray600 = Color(0xFF243152);      // Elevated
  static const Color darkBlueGray500 = Color(0xFF3B4663);
  static const Color darkBorder = Color(0xFF243152);

  // ── Light-mode neutrals ────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF5F7FB);            // Light gray cards
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFEEF1F6);

  // ── Semantic colours (work in both themes) ─────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Backwards-compatible aliases ──────────────────────────────────────────
  // Older widgets still reference these names. The values map to the
  // new premium palette so they still look correct.
  static const Color successGreen = Color(0xFF16A34A);     // light accent green
  static const Color infoBlue = Color(0xFF2563EB);         // modern blue
  static const Color secondaryTeal = Color(0xFF14B8A6);    // teal
  static const Color accentOrange = Color(0xFFF59E0B);     // amber
  static const Color warningAmber = Color(0xFFF59E0B);     // amber alias
  static const Color textPrimary = Color(0xFF0F172A);      // light text primary
  static const Color textSecondary = Color(0xFF475569);    // light text secondary

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color textPrimaryLight = Color(0xFF0F172A);     // dark text
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textHintLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);      // white text
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textHintDark = Color(0xFF94A3B8);

  // Grayscale ramp (kept for backwards compatibility with any legacy
  // widget that still references grayXXX — prefer tokens instead).
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);

  // Status (legacy)
  static const Color pending = Color(0xFFF59E0B);
  static const Color active = Color(0xFF22C55E);
  static const Color inactive = Color(0xFF94A3B8);
  static const Color completed = Color(0xFF16A34A);
  static const Color cancelled = Color(0xFFEF4444);

  // ── Gradients (read through theme tokens when possible) ────────────────────
  // Light: Modern Blue → Elegant Green (premium feel).
  // Used by the login button, brand surfaces, hero cards, and the
  // seller + buyer dashboards' greeting gradient.
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, accentGreen],
  );

  // Dark: Bright Blue → Teal Green over deep navy.
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBrightBlue, accentTealGreen],
  );

  // Deep navy hero gradient used on splash/login and brand surfaces
  // (dark theme).
  static const LinearGradient deepNavyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1220), Color(0xFF1D4ED8)],
  );

  // Light-theme hero gradient — soft ocean teal/sky-blue so the
  // light login screen reads as a sunny beach, not a dark cave.
  // The colors mirror the dark hero so swapping themes still feels
  // like the same brand.
  static const LinearGradient oceanLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5EEAD4), Color(0xFF0EA5E9)],
  );

  // Backwards-compatible alias used by some widgets.
  static const LinearGradient primaryGradient = lightGradient;
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, primaryBlue],
  );
}

/// The two theming modes the user can pick from. Persisted in
/// SharedPreferences (under [AppThemeMode.prefKey]) so the choice
/// survives app restarts and account switches.
enum AppThemeMode {
  /// Light theme — Modern Blue primary, Elegant Green accent.
  light,

  /// Dark theme — Deep Navy background, Bright Blue primary, Teal
  /// Green accent. No pure black.
  dark;

  /// Pretty-printed label shown in the Settings switcher.
  String get label => switch (this) {
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
      };

  /// Subtitle shown under the label in the switcher.
  String get subtitle => switch (this) {
        AppThemeMode.light => 'Clean white, Modern Blue & Elegant Green',
        AppThemeMode.dark => 'Deep Navy & Teal, easy on the eyes',
      };

  /// Storage key prefix for SharedPreferences. The full key is
  /// derived per-user so each signed-in account keeps its own theme
  /// choice (buyer, street seller, admin all share the same key
  /// derivation — theme is a personal preference, not a role-level
  /// or device-level setting).
  ///
  /// Use [prefKeyFor] when you have a uid; [prefKeyAnonymous] is the
  /// fallback for the brief window before sign-in completes.
  static const String _prefKeyPrefix = 'app.themeMode.v3';
  static const String prefKeyAnonymous = '$_prefKeyPrefix.guest';

  /// Per-user storage key. Pass the signed-in user's uid (or any
  /// stable string identifier) so each account keeps its own theme.
  static String prefKeyFor(String uid) => '$_prefKeyPrefix.user.$uid';

  /// Resolve from the persisted string. Falls back to [light] when
  /// the stored value is missing or comes from an older enum version
  /// (e.g. `cream`).
  static AppThemeMode fromName(String? raw) {
    if (raw == null) return AppThemeMode.light;
    for (final mode in AppThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    // Legacy values from previous app versions (e.g. "cream") map to
    // the closest modern equivalent.
    return AppThemeMode.light;
  }
}

/// A flat, immutable snapshot of every colour token a widget might
/// read from the active theme. Use this when a widget cannot rely on
/// `Theme.of(context)` (e.g. `BitmapDescriptor` markers, `Canvas`
/// drawing, custom shape painters).
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

  /// Light tokens — Modern Blue primary, Elegant Green accent.
  static const AppColorTokens light = AppColorTokens(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF5F7FB),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textHint: Color(0xFF94A3B8),
    primary: Color(0xFF2563EB),          // Modern Blue
    accent: Color(0xFF16A34A),           // Elegant Green
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    shadow: Color(0x14000000),           // 8% black
    brandGradient: AppColors.lightGradient,
  );

  /// Dark tokens — Deep Navy background, Bright Blue primary, Teal
  /// Green accent. No pure black.
  static const AppColorTokens dark = AppColorTokens(
    brightness: Brightness.dark,
    background: Color(0xFF0B1220),       // Deep Navy Blue
    surface: Color(0xFF1B2640),          // Blue-Gray surface
    surfaceAlt: Color(0xFF243152),       // Blue-Gray elevated
    border: Color(0xFF243152),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCBD5E1),
    textHint: Color(0xFF94A3B8),
    primary: Color(0xFF3B82F6),          // Bright Blue
    accent: Color(0xFF14B8A6),           // Teal Green
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    shadow: Color(0x33000000),           // 20% black
    brandGradient: AppColors.darkGradient,
  );

  /// Lookup by mode.
  static AppColorTokens of(AppThemeMode mode) => switch (mode) {
        AppThemeMode.light => light,
        AppThemeMode.dark => dark,
      };
}