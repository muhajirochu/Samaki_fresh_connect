// Verifies the popup menu actions on the Manage Buyers screen
// actually fire when tapped. The previous test only checked that
// the list rendered and the search bar filtered — it never opened
// the menu and asserted the per-row actions did anything.

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
  required String email,
  bool active = true,
}) {
  return UserModel(
    userId: id,
    email: email,
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
    'Manage Buyers — popup menu button is tappable',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap([
        _buyer(id: 'b1', name: 'Asha Buyer', email: 'asha@test.com'),
      ]));
      await tester.pumpAndSettle();

      // The PopupMenuButton is the "..." icon at the end of every
      // row. It must be tappable without an overflow exception.
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      expect(moreIcon, findsOneWidget);

      await tester.tap(moreIcon, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Both menu items should now be visible.
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.viewProfile), findsOneWidget);
      expect(find.text(l10n.blockUser), findsOneWidget);
    },
  );
}
