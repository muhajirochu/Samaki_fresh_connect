// Bundled-Poppins wrapper.
//
// Replaces `GoogleFonts.poppins(...)` everywhere in the theme code with
// a synchronous, network-free call to the Poppins font we ship in
// assets/fonts/. The Google Fonts package's runtime fetcher is gone —
// the first cold start no longer pays a fonts.googleapis.com RTT, and a
// fresh install on a metered or patchy connection no longer blocks on
// the text theme resolving before the splash navigates.
//
// The signature mirrors GoogleFonts.poppins(...) one-for-one so every
// call site in lib/config/{light,dark}_theme.dart compiles unchanged
// after the import swap.

import 'package:flutter/material.dart';

/// Returns a [TextStyle] rendered in the bundled Poppins family.
///
/// Behaves like `GoogleFonts.poppins(...)` for the parameters the
/// theme code actually uses — `fontSize`, `fontWeight`, `color`,
/// `letterSpacing`, `height`. Other GoogleFonts parameters
/// (`textStyle`, `fontStyle`, etc.) are intentionally not exposed; if
/// the theme ever needs them, add them here rather than re-introducing
/// the network fetch.
TextStyle appPoppins({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: const ['Roboto', 'sans-serif'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// Drop-in replacement for `GoogleFonts.poppinsTextTheme()`.
///
/// Returns a [TextTheme] whose only override is the font family — every
/// size / weight / colour from the existing [base] is kept, and
/// `fontFamily` is pointed at the bundled Poppins asset so the platform
/// never has to fetch anything.
TextTheme appPoppinsTextTheme([TextTheme? base]) {
  final fallback = base ?? const TextTheme();
  return fallback.apply(
    fontFamily: 'Poppins',
    fontFamilyFallback: const ['Roboto', 'sans-serif'],
  );
}
