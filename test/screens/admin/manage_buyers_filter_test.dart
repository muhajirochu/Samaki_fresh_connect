// Verifies the status filter chips on Manage Buyers. The
// manage_buyers_screen_test only checks the list renders; this
// test specifically drives the All / Active / Suspended filter and
// asserts the visible row set changes accordingly.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/config/dark_theme.dart';
import 'package:samakifresh_connect/config/light_theme.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/providers/admin_provider.dart';
import 'package:samakifresh_connect/screens/admin/manage_buyers_screen.dart';

UserModel _buyer({
  required String id,
  required String name,
  required bool active,
}) {
  return UserModel(
    userId: id,
    email: '$id@test.com',
    fullName: name,
    phoneNumber: '+255700000002',
    role: UserRole.buyer,
    isActive: active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(List<UserModel> buyers) {
  return ProviderScope(
    overrides: [
      adminAllBuyersProvider.overrideWith(
        (ref) => Stream.value(buyers),
      ),
    ],
    child: MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ManageBuyersScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'Manage Buyers — Suspended chip hides active buyers',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final buyers = [
        _buyer(id: 'b1', name: 'Active Asha', active: true),
        _buyer(id: 'b2', name: 'Suspended Salim', active: false),
      ];

      await tester.pumpWidget(_wrap(buyers));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // Both render under the All chip.
      expect(find.text('Active Asha'), findsOneWidget);
      expect(find.text('Suspended Salim'), findsOneWidget);

      // Tap Suspended chip — active row should disappear.
      await tester.tap(find.text(l10n.suspendedBadge));
      await tester.pumpAndSettle();

      expect(find.text('Active Asha'), findsNothing);
      expect(find.text('Suspended Salim'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Buyers — Active chip hides suspended buyers',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final buyers = [
        _buyer(id: 'b1', name: 'Active Asha', active: true),
        _buyer(id: 'b2', name: 'Suspended Salim', active: false),
      ];

      await tester.pumpWidget(_wrap(buyers));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // Tap Active chip.
      await tester.tap(find.text(l10n.filterActive));
      await tester.pumpAndSettle();

      expect(find.text('Active Asha'), findsOneWidget);
      expect(find.text('Suspended Salim'), findsNothing);
    },
  );
}
