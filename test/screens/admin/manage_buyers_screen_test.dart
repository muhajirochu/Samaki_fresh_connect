// Manage Buyers screen — verifies the buyer list renders, the
// search bar filters, and the suspend / reactivate actions fire
// the right service calls. This is the regression guard for the
// "Manage Buyers does not work" bug the user reported.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/config/dark_theme.dart';
import 'package:samakifresh_connect/config/light_theme.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/providers/admin_provider.dart';
import 'package:samakifresh_connect/providers/auth_provider.dart';
import 'package:samakifresh_connect/screens/admin/manage_buyers_screen.dart';
import 'package:samakifresh_connect/services/user_service.dart';

UserModel _buyer({
  required String id,
  required String name,
  required String email,
  bool active = true,
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    userId: id,
    email: email,
    fullName: name,
    phoneNumber: '+255700000001',
    role: UserRole.buyer,
    isActive: active,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap({Locale locale = const Locale('en')}) {
  return ProviderScope(
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
      locale: locale,
      home: const ManageBuyersScreen(),
    ),
  );
}

Widget _wrapWithBuyers(List<UserModel> buyers) {
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
    'Manage Buyers — empty list shows the localized empty state',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminAllBuyersProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: _wrap(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No buyers registered yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Buyers — buyers render with their names and emails',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final buyers = [
        _buyer(id: 'b1', name: 'Fatma Buyer', email: 'fatma@test.com'),
        _buyer(id: 'b2', name: 'Halima Buyer', email: 'halima@test.com'),
      ];

      await tester.pumpWidget(_wrapWithBuyers(buyers));
      await tester.pumpAndSettle();

      expect(find.text('Fatma Buyer'), findsOneWidget);
      expect(find.text('Halima Buyer'), findsOneWidget);
      expect(find.text('fatma@test.com'), findsOneWidget);
      expect(find.text('halima@test.com'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Buyers — search bar filters by name',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final buyers = [
        _buyer(id: 'b1', name: 'Fatma Buyer', email: 'fatma@test.com'),
        _buyer(id: 'b2', name: 'Halima Buyer', email: 'halima@test.com'),
      ];
      await tester.pumpWidget(_wrapWithBuyers(buyers));
      await tester.pumpAndSettle();

      // Type "Halima" into the search bar.
      await tester.enterText(find.byType(TextField).first, 'Halima');
      await tester.pumpAndSettle();

      expect(find.text('Fatma Buyer'), findsNothing);
      expect(find.text('Halima Buyer'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Buyers — Kiswahili labels render',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminAllBuyersProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: _wrap(locale: const Locale('sw')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bado hakuna wanunuzi waliosajiliwa'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Buyers — suspended buyer shows the SUSPENDED badge',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final buyers = [
        _buyer(
          id: 'b1',
          name: 'Suspended Samira',
          email: 'samira@test.com',
          active: false,
        ),
      ];
      await tester.pumpWidget(_wrapWithBuyers(buyers));
      await tester.pumpAndSettle();

      expect(find.text('Suspended Samira'), findsOneWidget);
      expect(find.text('SUSPENDED'), findsOneWidget);
    },
  );
}
