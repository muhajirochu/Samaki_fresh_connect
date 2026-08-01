// Dark theme for Samaki Fresh Connect.
//
// Design reference: Deep Navy Blue background (#0D1B2A), layered
// midnight-navy cards (#112236 / #132D4A), bright Ocean Teal
// accents (#38BDF8 / #2DD4BF). Deliberately NOT pure black —
// the enterprise fishery-market feel comes from a layered navy palette
// with teal highlights that pop against the dark.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'light_theme.dart' show buildPoppinsTextTheme;
import 'theme_extensions.dart';

ThemeData buildDarkTheme() {
  const tokens = AppColorTokens.dark;

  final colorScheme = ColorScheme.fromSeed(
    seedColor:  AppColors.primaryTeal,
    brightness: Brightness.dark,
    secondary:  AppColors.accentTeal,
    tertiary:   AppColors.primaryCyanLight,
    error:      tokens.error,
    surface:    tokens.surface,
  ).copyWith(
    primary:                   tokens.primary,
    onPrimary:                 AppColors.darkNavy900,
    secondary:                 tokens.accent,
    onSecondary:               AppColors.darkNavy900,
    onSurface:                 tokens.textPrimary,
    onError:                   AppColors.darkNavy900,
    surfaceContainerHighest:   tokens.surfaceAlt,
    surfaceContainerHigh:      const Color(0xFF152840),
    surfaceContainer:          tokens.surface,
    surfaceContainerLow:       const Color(0xFF0F1E30),
    surfaceContainerLowest:    const Color(0xFF09141F),
    outline:                   tokens.border,
    outlineVariant:            const Color(0xFF193347),
    shadow:                    tokens.shadow,
  );

  final textTheme = buildPoppinsTextTheme(
    textPrimary:   tokens.textPrimary,
    textSecondary: tokens.textSecondary,
    textHint:      tokens.textHint,
  );

  return ThemeData(
    useMaterial3:            true,
    brightness:              Brightness.dark,
    primaryColor:            tokens.primary,
    scaffoldBackgroundColor: tokens.background,
    canvasColor:             tokens.background,
    fontFamily:              'Poppins',
    textTheme:               textTheme,
    primaryTextTheme:        textTheme,
    colorScheme:             colorScheme,
    splashFactory:           InkSparkle.splashFactory,
    iconTheme:    IconThemeData(color: tokens.textPrimary, size: AppSizes.iconMD),
    primaryIconTheme: const IconThemeData(color: AppColors.darkNavy900),

    appBarTheme: AppBarTheme(
      backgroundColor:      tokens.background,
      foregroundColor:      tokens.textPrimary,
      elevation:            0,
      scrolledUnderElevation: 0.5,
      centerTitle:          false,
      iconTheme:            IconThemeData(color: tokens.textPrimary),
      titleTextStyle: GoogleFonts.poppins(
        fontSize:     AppSizes.fontLG,
        fontWeight:   FontWeight.w600,
        color:        tokens.textPrimary,
        letterSpacing: -0.2,
      ),
    ),

    cardTheme: CardThemeData(
      elevation:        0,
      color:            tokens.surface,
      shadowColor:      tokens.shadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        side: BorderSide(color: tokens.border, width: 0.8),
      ),
      margin: EdgeInsets.zero,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: AppColors.darkNavy900,
        elevation:       0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXL,
          vertical:   AppSizes.paddingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize:   AppSizes.fontMD,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: AppColors.darkNavy900,
        elevation:       0,
        shadowColor:     tokens.shadow,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXL,
          vertical:   AppSizes.paddingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize:   AppSizes.fontMD,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.primary,
        side: BorderSide(color: tokens.primary, width: 1.2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXL,
          vertical:   AppSizes.paddingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize:   AppSizes.fontMD,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical:   AppSizes.paddingSM,
        ),
        textStyle: GoogleFonts.poppins(
          fontSize:   AppSizes.fontMD,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled:      true,
      fillColor:   const Color(0xFF0F1E30),    // slightly lighter than background
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical:   AppSizes.paddingMD,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        borderSide: BorderSide(color: tokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        borderSide: BorderSide(color: tokens.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        borderSide: BorderSide(color: tokens.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        borderSide: BorderSide(color: tokens.error, width: 1.8),
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontMD,
        fontWeight: FontWeight.normal,
        color:      tokens.textHint,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontMD,
        fontWeight: FontWeight.w500,
        color:      tokens.textSecondary,
      ),
    ),

    dividerTheme: DividerThemeData(
      color:     tokens.border,
      thickness: 0.6,
      space:     0,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor:      tokens.surface,
      surfaceTintColor:     Colors.transparent,
      modalBackgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.surfaceAlt,
      contentTextStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontMD,
        fontWeight: FontWeight.w500,
        color:      tokens.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    listTileTheme: ListTileThemeData(
      iconColor:  tokens.textSecondary,
      textColor:  tokens.textPrimary,
      tileColor:  tokens.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical:   AppSizes.paddingXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor:           tokens.primary,
      unselectedLabelColor: tokens.textSecondary,
      indicatorColor:       tokens.primary,
      indicatorSize:        TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontMD,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontMD,
        fontWeight: FontWeight.w500,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.surface,
      indicatorColor:  tokens.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.poppins(
          fontSize:   AppSizes.fontXS,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: tokens.textPrimary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? tokens.primary
              : tokens.textSecondary,
        ),
      ),
      elevation: 0,
      height:    68,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor:  tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation:        12,
      shadowColor:      tokens.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontXL,
        fontWeight: FontWeight.w600,
        color:      tokens.textPrimary,
      ),
      contentTextStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontMD,
        fontWeight: FontWeight.w400,
        color:      tokens.textSecondary,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: tokens.surfaceAlt,
      selectedColor:   tokens.primary,
      labelStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontSM,
        fontWeight: FontWeight.w500,
        color:      tokens.textPrimary,
      ),
      side: BorderSide(color: tokens.border, width: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? tokens.primary
            : tokens.textHint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? tokens.primary.withValues(alpha: 0.40)
            : tokens.border,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor:   tokens.primary,
      inactiveTrackColor: tokens.border,
      thumbColor:         tokens.primary,
      overlayColor:       tokens.primary.withValues(alpha: 0.16),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color:              tokens.primary,
      linearTrackColor:   tokens.border,
      circularTrackColor: tokens.border,
    ),

    extensions: <ThemeExtension<dynamic>>[
      BackgroundStyle(
        background: tokens.background,
        surface:    tokens.surface,
        surfaceAlt: tokens.surfaceAlt,
        border:     tokens.border,
      ),
      const GlassStyle(
        surface: Color(0x2238BDF8),           // teal-tinted glass
        border:  Color(0x3038BDF8),           // teal-tinted border
        highlight: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0x2238BDF8), Color(0x0038BDF8)],
        ),
      ),
      AppGradients.dark,
    ],
  );
}
