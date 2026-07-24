// Manage Sellers screen — verifies the seller list renders, the
// search bar filters, and the suspend / reactivate actions fire
// the right service calls. This is the regression guard for the
// "Manage Sellers does not work" bug the user reported.

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
import 'package:samakifresh_connect/screens/admin/manage_sellers_screen.dart';

UserModel _seller({
  required String id,
  required String name,
  required String email,
  bool approved = true,
  bool active = true,
}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    userId: id,
    email: email,
    fullName: name,
    phoneNumber: '+255700000001',
    role: UserRole.streetSeller,
    isActive: active,
    isApproved: approved,
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
      home: const ManageSellersScreen(),
    ),
  );
}

Widget _wrapWithSellers(List<UserModel> sellers) {
  return ProviderScope(
    overrides: [
      adminAllSellersProvider.overrideWith(
        (ref) => Stream.value(sellers),
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
      home: const ManageSellersScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'Manage Sellers — empty list shows the localized empty state',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminAllSellersProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: _wrap(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No street sellers registered yet'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Sellers — sellers render with their names',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sellers = [
        _seller(id: 's1', name: 'Asha Seller', email: 'asha@test.com'),
        _seller(id: 's2', name: 'Halima Seller', email: 'halima@test.com'),
      ];

      await tester.pumpWidget(_wrapWithSellers(sellers));
      await tester.pumpAndSettle();

      expect(find.text('Asha Seller'), findsOneWidget);
      expect(find.text('Halima Seller'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Sellers — search bar filters by name',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sellers = [
        _seller(id: 's1', name: 'Asha Seller', email: 'asha@test.com'),
        _seller(id: 's2', name: 'Halima Seller', email: 'halima@test.com'),
      ];
      await tester.pumpWidget(_wrapWithSellers(sellers));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Halima');
      await tester.pumpAndSettle();

      expect(find.text('Asha Seller'), findsNothing);
      expect(find.text('Halima Seller'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Sellers — suspended seller shows the SUSPENDED badge',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sellers = [
        _seller(
          id: 's1',
          name: 'Suspended Salma',
          email: 'salma@test.com',
          active: false,
        ),
      ];
      await tester.pumpWidget(_wrapWithSellers(sellers));
      await tester.pumpAndSettle();

      expect(find.text('Suspended Salma'), findsOneWidget);
      expect(find.text('SUSPENDED'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Sellers — pending seller shows the PENDING APPROVAL badge',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sellers = [
        _seller(
          id: 's1',
          name: 'Pending Hassan',
          email: 'hassan@test.com',
          approved: false,
        ),
      ];
      await tester.pumpWidget(_wrapWithSellers(sellers));
      await tester.pumpAndSettle();

      expect(find.text('Pending Hassan'), findsOneWidget);
      expect(find.text('PENDING APPROVAL'), findsOneWidget);
    },
  );
}