// Visual smoke tests for the polished premium UI.
//
// Runs `SettingsScreen` in both light and dark themes, and verifies
// the theme token system is wired correctly.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/config/dark_theme.dart';
import 'package:samakifresh_connect/config/light_theme.dart';
import 'package:samakifresh_connect/config/theme_extensions.dart';
import 'package:samakifresh_connect/constants/app_colors.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/providers/locale_provider.dart';
import 'package:samakifresh_connect/providers/theme_provider.dart';
import 'package:samakifresh_connect/providers/user_preferences_provider.dart';
import 'package:samakifresh_connect/screens/common/settings_screen.dart';

Widget _wrap({
  required Widget child,
  required ThemeData theme,
  required AppThemeMode mode,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      themeControllerProvider.overrideWith(
        (ref) => ThemeModeNotifier(mode, ''),
      ),
      localeProvider.overrideWith((ref) => locale),
      // Settings now consumes [userPreferencesProvider]; pin it to a
      // fixed default so the test isn't dependent on the host
      // machine's SharedPreferences.
      userPreferencesProvider.overrideWith(
        (ref) => UserPreferencesNotifier('test-uid'),
      ),
    ],
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
    ),
  );
}

void main() {
  testWidgets('Settings — light', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        child: const SettingsScreen(),
        theme: buildLightTheme(),
        mode: AppThemeMode.light,
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Pull the localized strings out at test time so the test
    // remains correct when the ARB changes.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.appearance), findsOneWidget);
    expect(find.text(l10n.language), findsAtLeastNWidgets(1),
        reason: 'settings must show the language section and tile');
  });

  testWidgets('Settings — dark', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        child: const SettingsScreen(),
        theme: buildDarkTheme(),
        mode: AppThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.appearance), findsOneWidget);
    expect(find.text(l10n.language), findsAtLeastNWidgets(1));
  });

  testWidgets('Theme tokens differ between modes', (tester) async {
    final light = AppColorTokens.of(AppThemeMode.light);
    final dark = AppColorTokens.of(AppThemeMode.dark);

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(dark.background, isNot(light.background));
    expect(dark.textPrimary, isNot(light.textPrimary));
  });

  testWidgets('Premium glass tokens load', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildDarkTheme(),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // GlassStyle should be reachable via the dark theme extension.
    final ctx = tester.element(find.byType(Scaffold));
    final glass = GlassStyle.of(ctx);
    expect(glass.border, isA<Color>());
    expect(glass.surface, isA<Color>());
  });

  testWidgets('Settings exposes the language picker tile', (tester) async {
    // The Settings hub now contains a Language section. Tapping it
    // should open the dedicated LanguageSelectorScreen.
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        child: const SettingsScreen(),
        theme: buildLightTheme(),
        mode: AppThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.language), findsWidgets,
        reason: 'settings must show the language tile');
  });
}