// Three coordinated Material 3 themes for the Fresh Connect app:
//
//   • `AppThemes.light()` — pure white surfaces, navy text. Default
//     daylight mode for strong contrast and OS-consistent look.
//   • `AppThemes.cream()` — warm off-white surfaces, brown text.
//     Premium "paper" feel that's easy on the eyes over long
//     sessions; pairs well with the ocean/teal primary colour.
//   • `AppThemes.dark()`  — navy / slate surfaces, soft white text.
//     Low-light friendly with the same primary hue desaturated.
//
// All three themes share the same typography (Poppins via
// google_fonts) and the same component radii/padding so screens
// render identically apart from colour. Switching is cheap because
// widgets read colors through `Theme.of(context)` /
// `AppColorTokens.of(...)` — only the Material widgets that depend
// on `ColorScheme` need a single rebuild.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppThemes {
  /// Returns the theme matching the given [AppThemeMode].
  static ThemeData forMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light();
      case AppThemeMode.cream:
        return cream();
      case AppThemeMode.dark:
        return dark();
    }
  }

  /// LIGHT theme — pure white surface, navy text.
  static ThemeData light() => _buildTheme(
        brightness: Brightness.light,
        primary: AppColors.primaryBlue,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryTeal,
        tertiary: AppColors.accentOrange,
        background: Colors.white,
        surface: Colors.white,
        surfaceAlt: AppColors.gray100,
        border: AppColors.gray200,
        textPrimary: AppColors.gray900,
        textSecondary: AppColors.gray700,
        textHint: AppColors.gray500,
        onSurface: AppColors.gray900,
        scaffoldBackground: Colors.white,
        appBarBg: Colors.white,
        inputFill: AppColors.gray100,
        cardBg: Colors.white,
        iconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      );

  /// CREAM theme — warm off-white surface, deep brown text. Uses a
  /// slightly desaturated teal/orange palette so the UI reads as
  /// "premium / paper" rather than the default playful light mode.
  static ThemeData cream() => _buildTheme(
        brightness: Brightness.light,
        primary: const Color(0xFFB45309), // warm amber
        onPrimary: Colors.white,
        secondary: const Color(0xFF007B6B), // secondary teal dark
        tertiary: const Color(0xFFE65C2B), // accent orange dark
        background: AppColors.cream50,
        surface: AppColors.cream100,
        surfaceAlt: AppColors.cream200,
        border: AppColors.cream300,
        textPrimary: AppColors.creamTextPrimary,
        textSecondary: AppColors.creamTextSecondary,
        textHint: AppColors.creamShadow,
        onSurface: AppColors.creamTextPrimary,
        scaffoldBackground: AppColors.cream50,
        appBarBg: AppColors.cream100,
        inputFill: AppColors.cream200,
        cardBg: AppColors.cream100,
        iconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      );

  /// DARK theme — navy / slate surfaces, soft white text.
  static ThemeData dark() => _buildTheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryBlueLight,
        onPrimary: AppColors.dark900,
        secondary: AppColors.secondaryTealLight,
        tertiary: AppColors.accentOrangeLight,
        background: AppColors.dark900,
        surface: AppColors.dark800,
        surfaceAlt: AppColors.dark700,
        border: AppColors.dark700,
        textPrimary: AppColors.dark100,
        textSecondary: AppColors.dark300,
        textHint: AppColors.dark500,
        onSurface: AppColors.dark100,
        scaffoldBackground: AppColors.dark900,
        appBarBg: AppColors.dark800,
        inputFill: AppColors.dark700,
        cardBg: AppColors.dark800,
        iconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      );

  // ── Internal builder ──────────────────────────────────────────────────────
  // Every theme shares the same typography, shape, spacing, and
  // component themes — only the colour tokens differ. This keeps the
  // UI consistent across modes while letting us flip the whole app
  // theme with a single token swap.

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color tertiary,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textHint,
    required Color onSurface,
    required Color scaffoldBackground,
    required Color appBarBg,
    required Color inputFill,
    required Color cardBg,
    required Brightness iconBrightness,
    required Brightness statusBarBrightness,
  }) {
    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: AppSizes.font4XL,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: AppSizes.font3XL,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontXXL,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontXL,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontLG,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: AppSizes.fontXS,
        fontWeight: FontWeight.w500,
        color: textHint,
      ),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onPrimary,
      tertiary: tertiary,
      onTertiary: onPrimary,
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceAlt,
      surfaceContainerHigh: surfaceAlt,
      surfaceContainer: surfaceAlt,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      fontFamily: 'Poppins',
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      colorScheme: colorScheme,
      iconTheme: IconThemeData(color: onSurface),
      primaryIconTheme: IconThemeData(color: onPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontLG,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        minWidth: AppSizes.buttonHeight,
        height: AppSizes.buttonHeight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSizes.radiusMD),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLG,
            vertical: AppSizes.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLG,
            vertical: AppSizes.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.normal,
          color: textHint,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          side: BorderSide(color: border),
        ),
        color: cardBg,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 0.5,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLG),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w500,
          color: scaffoldBackground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
      ),
      extensions: <ThemeExtension<dynamic>>[
        _BackgroundStyle(
          background: scaffoldBackground,
          surface: surface,
          surfaceAlt: surfaceAlt,
          border: border,
        ),
      ],
    );
  }
}

/// Custom theme extension carrying the four surface tokens we read
/// from outside the standard [ColorScheme]. Keeps widgets from having
/// to hard-code `AppColors.gray50` etc. and lets the cream / dark
/// themes look correct.
class _BackgroundStyle extends ThemeExtension<_BackgroundStyle> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;

  const _BackgroundStyle({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
  });

  @override
  _BackgroundStyle copyWith() => this;

  @override
  _BackgroundStyle lerp(
      ThemeExtension<_BackgroundStyle>? other, double t) {
    if (other is! _BackgroundStyle) return this;
    return _BackgroundStyle(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Public extension that lets widgets read the background tokens
/// through `Theme.of(context).extension<BackgroundStyle>()`.
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

  static BackgroundStyle of(BuildContext context) {
    return Theme.of(context).extension<BackgroundStyle>() ??
        const BackgroundStyle(
          background: Colors.white,
          surface: Colors.white,
          surfaceAlt: Color(0xFFF5F5F5),
          border: Color(0xFFEEEEEE),
        );
  }

  @override
  BackgroundStyle copyWith() => this;

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
