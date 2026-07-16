// Barrel file re-exporting the two ThemeData builders used by the app:
//
//   • `buildLightTheme()` — clean white surface, Modern Blue primary,
//     Elegant Green accent. Premium / minimalist.
//   • `buildDarkTheme()`  — Deep Navy background, Bright Blue primary,
//     Teal Green accent. Modern enterprise dashboard feel.
//
// Both themes share the same typography (Poppins via google_fonts),
// the same component shapes/radii, and the same [BackgroundStyle],
// [GlassStyle], and [AppGradients] token indirection. Switching is
// cheap because widgets read colors through `Theme.of(context)` or
// the theme extensions — only Material widgets bound to `ColorScheme`
// need a single rebuild.

export 'dark_theme.dart';
export 'light_theme.dart';
export 'theme_extensions.dart';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

/// Convenience: pick the right [ThemeData] for the given [mode].
ThemeData buildThemeForMode(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return buildLightTheme();
    case AppThemeMode.dark:
      return buildDarkTheme();
  }
}