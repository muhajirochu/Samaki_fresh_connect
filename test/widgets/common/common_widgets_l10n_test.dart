// Regression tests for the localized strings on shared common widgets:
//   * CustomTextField password toggle: Show / Hide
//   * EmptyStateWidget retry button: Retry
//
// These strings used to be hardcoded English — the previous
// widget tests passed because English happened to be the
// system locale, but a Swahili user would see English buttons
// even after picking Kiswahili in the locale switcher.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/config/dark_theme.dart';
import 'package:samakifresh_connect/config/light_theme.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/widgets/common/common_widgets.dart';

Widget _wrap({
  required Widget child,
  required Locale locale,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets(
    'CustomTextField password toggle starts as Show in English',
    (tester) async {
      await tester.pumpWidget(_wrap(
        child: const CustomTextField(
          label: 'Password',
          isPasswordField: true,
        ),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
      // Initial state is obscured, so the toggle button reads "Show".
      expect(find.text('Show'), findsOneWidget);
      // Tap it — button must flip to "Hide".
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Hide'), findsOneWidget);
    },
  );

  testWidgets(
    'CustomTextField password toggle starts as Onyesha in Kiswahili',
    (tester) async {
      await tester.pumpWidget(_wrap(
        child: const CustomTextField(
          label: 'Password',
          isPasswordField: true,
        ),
        locale: const Locale('sw'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Onyesha'), findsOneWidget);
      await tester.tap(find.text('Onyesha'));
      await tester.pumpAndSettle();
      expect(find.text('Ficha'), findsOneWidget);
    },
  );

  testWidgets(
    'EmptyStateWidget retry button shows localized Retry in English',
    (tester) async {
      await tester.pumpWidget(_wrap(
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Oops',
          onRetry: () {},
        ),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'EmptyStateWidget retry button shows localized Jaribu tena in Kiswahili',
    (tester) async {
      await tester.pumpWidget(_wrap(
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Oops',
          onRetry: () {},
        ),
        locale: const Locale('sw'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Jaribu tena'), findsOneWidget);
    },
  );
}
