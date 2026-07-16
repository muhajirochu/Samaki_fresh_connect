// Shared [ThemeExtension]s used across both light and dark themes.
//
// These give widgets a typed accessor for tokens that don't live on
// `ColorScheme` (e.g. background/surface/border gradients,
// glassmorphism overlays, brand gradients). Read them via
// `Theme.of(context).extension<...>()`.

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Background/surface/border tokens for the current theme.
class BackgroundStyle extends ThemeExtension<BackgroundStyle> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;

  const BackgroundStyle({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
  });

  /// Convenience lookup that returns a sane fallback if the theme
  /// hasn't been built yet.
  static BackgroundStyle of(BuildContext context) {
    return Theme.of(context).extension<BackgroundStyle>() ??
        const BackgroundStyle(
          background: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFF5F7FB),
          border: Color(0xFFE5E7EB),
        );
  }

  @override
  BackgroundStyle copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
  }) {
    return BackgroundStyle(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
    );
  }

  @override
  BackgroundStyle lerp(ThemeExtension<BackgroundStyle>? other, double t) {
    if (other is! BackgroundStyle) return this;
    return BackgroundStyle(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Glassmorphism tokens — translucent overlays used for premium
/// "frosted glass" surfaces such as the auth screens and hero
/// cards.
class GlassStyle extends ThemeExtension<GlassStyle> {
  /// Slightly tinted surface for glass panels.
  final Color surface;

  /// Border colour (subtle white-on-dark, gray-on-light).
  final Color border;

  /// Highlight gradient (top-left bright, bottom-right transparent).
  final LinearGradient highlight;

  /// Default fallback tokens for the LIGHT theme.
  static const GlassStyle light = GlassStyle(
    surface: Color(0x66FFFFFF),
    border: Color(0x33000000),
    highlight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
    ),
  );

  /// Default fallback tokens for the DARK theme.
  static const GlassStyle dark = GlassStyle(
    surface: Color(0x331E3A8A),
    border: Color(0x33FFFFFF),
    highlight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
    ),
  );

  const GlassStyle({
    required this.surface,
    required this.border,
    required this.highlight,
  });

  static GlassStyle of(BuildContext context) {
    return Theme.of(context).extension<GlassStyle>() ?? GlassStyle.light;
  }

  @override
  GlassStyle copyWith({
    Color? surface,
    Color? border,
    LinearGradient? highlight,
  }) {
    return GlassStyle(
      surface: surface ?? this.surface,
      border: border ?? this.border,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  GlassStyle lerp(ThemeExtension<GlassStyle>? other, double t) {
    if (other is! GlassStyle) return this;
    return GlassStyle(
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: LinearGradient(
        colors: [
          Color.lerp(highlight.colors.first, other.highlight.colors.first, t)!,
          Color.lerp(highlight.colors.last, other.highlight.colors.last, t)!,
        ],
      ),
    );
  }
}

/// Brand gradients for the current theme.
class AppGradients extends ThemeExtension<AppGradients> {
  /// Primary brand gradient (Modern Blue → Elegant Green in light,
  /// Bright Blue → Teal Green in dark).
  final LinearGradient brand;

  /// Deep navy hero gradient — used by the splash screen and brand
  /// surfaces that should stay dark in both themes.
  final LinearGradient hero;

  const AppGradients({required this.brand, required this.hero});

  static const AppGradients light = AppGradients(
    brand: AppColors.lightGradient,
    hero: AppColors.deepNavyGradient,
  );

  static const AppGradients dark = AppGradients(
    brand: AppColors.darkGradient,
    hero: AppColors.deepNavyGradient,
  );

  static AppGradients of(BuildContext context) {
    return Theme.of(context).extension<AppGradients>() ?? AppGradients.light;
  }

  @override
  AppGradients copyWith({LinearGradient? brand, LinearGradient? hero}) {
    return AppGradients(brand: brand ?? this.brand, hero: hero ?? this.hero);
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      brand: brand,
      hero: hero,
    );
  }
}