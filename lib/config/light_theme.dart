// Light theme for Samaki Fresh Connect.
//
// Design reference: Clean white background (pure white), Ocean Teal
// (#0EA5E9) primary, Cyan (#06B6D4) accent, with wavy teal gradient
// headers on auth screens.
//
// ● Scaffold background : pure white (#FFFFFF)
// ● Cards / surfaces    : white with subtle teal-tinted border (sky-100)
// ● Primary color       : Ocean Teal (#0EA5E9)
// ● Inputs              : white fill, sky-100 border, teal focus ring
// ● Buttons             : teal→cyan gradient (via decoration on key screens)
// ● Text                : deep navy (#0C1F2C) primary, blue-gray secondary

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'theme_extensions.dart';

ThemeData buildLightTheme() {
  const tokens = AppColorTokens.light;

  final textTheme = buildPoppinsTextTheme(
    textPrimary:   tokens.textPrimary,
    textSecondary: tokens.textSecondary,
    textHint:      tokens.textHint,
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor:  AppColors.primaryTeal,
    brightness: Brightness.light,
    secondary:  AppColors.accentTeal,
    tertiary:   AppColors.primaryCyan,
    error:      tokens.error,
    surface:    tokens.surface,
  ).copyWith(
    primary:                   tokens.primary,
    onPrimary:                 AppColors.white,
    secondary:                 tokens.accent,
    onSecondary:               AppColors.white,
    onSurface:                 tokens.textPrimary,
    onError:                   AppColors.white,
    surfaceContainerHighest:   tokens.surfaceAlt,
    surfaceContainerHigh:      tokens.surfaceAlt,
    surfaceContainer:          tokens.surface,
    surfaceContainerLow:       const Color(0xFFF8FBFF),
    surfaceContainerLowest:    AppColors.white,
    outline:                   tokens.border,
    outlineVariant:            AppColors.lightDivider,
    shadow:                    tokens.shadow,
  );

  return ThemeData(
    useMaterial3:            true,
    brightness:              Brightness.light,
    primaryColor:            tokens.primary,
    scaffoldBackgroundColor: tokens.background,
    canvasColor:             tokens.background,
    fontFamily:              'Poppins',
    textTheme:               textTheme,
    primaryTextTheme:        textTheme,
    colorScheme:             colorScheme,
    splashFactory:           InkSparkle.splashFactory,
    iconTheme:    IconThemeData(color: tokens.textPrimary, size: AppSizes.iconMD),
    primaryIconTheme: const IconThemeData(color: AppColors.white),

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
      elevation:         0,
      color:             tokens.surface,
      shadowColor:       tokens.shadow,
      surfaceTintColor:  Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        side: BorderSide(color: tokens.border, width: 0.8),
      ),
      margin: EdgeInsets.zero,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
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
        foregroundColor: AppColors.white,
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
      fillColor:   AppColors.white,
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
      backgroundColor: tokens.textPrimary,
      contentTextStyle: GoogleFonts.poppins(
        fontSize:   AppSizes.fontMD,
        fontWeight: FontWeight.w500,
        color:      tokens.background,
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
      backgroundColor:  tokens.surface,
      indicatorColor:   tokens.primary.withValues(alpha: 0.12),
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
      elevation:        8,
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
            ? tokens.primary.withValues(alpha: 0.30)
            : tokens.border,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor:   tokens.primary,
      inactiveTrackColor: tokens.border,
      thumbColor:         tokens.primary,
      overlayColor:       tokens.primary.withValues(alpha: 0.10),
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
        surface:   Color(0x99FFFFFF),
        border:    Color(0x280EA5E9),         // teal-tinted glass border
        highlight: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
        ),
      ),
      AppGradients.light,
    ],
  );
}

// ── Shared Poppins text theme ─────────────────────────────────────────────────
TextTheme buildPoppinsTextTheme({
  required Color textPrimary,
  required Color textSecondary,
  required Color textHint,
}) {
  return GoogleFonts.poppinsTextTheme().copyWith(
    displayLarge: GoogleFonts.poppins(
      fontSize:     AppSizes.font4XL,
      fontWeight:   FontWeight.w700,
      color:        textPrimary,
      letterSpacing: -0.5,
      height:       1.15,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize:     AppSizes.font3XL,
      fontWeight:   FontWeight.w700,
      color:        textPrimary,
      letterSpacing: -0.5,
      height:       1.2,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize:     AppSizes.fontXXL,
      fontWeight:   FontWeight.w700,
      color:        textPrimary,
      letterSpacing: -0.4,
      height:       1.2,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize:     AppSizes.fontXXL,
      fontWeight:   FontWeight.w600,
      color:        textPrimary,
      letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize:     AppSizes.fontXL,
      fontWeight:   FontWeight.w600,
      color:        textPrimary,
      letterSpacing: -0.2,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize:     AppSizes.fontLG,
      fontWeight:   FontWeight.w600,
      color:        textPrimary,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize:   AppSizes.fontLG,
      fontWeight: FontWeight.w600,
      color:      textPrimary,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize:   AppSizes.fontMD,
      fontWeight: FontWeight.w600,
      color:      textPrimary,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize:   AppSizes.fontSM,
      fontWeight: FontWeight.w600,
      color:      textPrimary,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize:   AppSizes.fontMD,
      fontWeight: FontWeight.normal,
      color:      textPrimary,
      height:     1.5,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize:   AppSizes.fontSM,
      fontWeight: FontWeight.normal,
      color:      textSecondary,
      height:     1.5,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize:   AppSizes.fontXS,
      fontWeight: FontWeight.normal,
      color:      textSecondary,
      height:     1.5,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize:   AppSizes.fontMD,
      fontWeight: FontWeight.w600,
      color:      textPrimary,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize:   AppSizes.fontSM,
      fontWeight: FontWeight.w500,
      color:      textPrimary,
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize:     AppSizes.fontXS,
      fontWeight:   FontWeight.w500,
      color:        textHint,
      letterSpacing: 0.2,
    ),
  );
}