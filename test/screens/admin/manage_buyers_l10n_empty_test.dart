// Regression tests for the admin Manage Buyers fixes:
//
// 1. Localized filter chips — "All" / "Active" / "Suspended" must
//    come from AppLocalizations in both EN and SW (no more hardcoded
//    English labels).
// 2. Filter empty state — when a search query matches no buyer the
//    screen renders the localized "noMatchingBuyers" message instead
//    of a blank list.
// 3. Sort — suspended buyers drop to the bottom of the visual stack
//    regardless of createdAt ordering (matches the file's doc comment).
// 4. Pull-to-refresh works even when the filtered list is short —
//    AlwaysScrollableScrollPhysics keeps the indicator reachable.

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
  DateTime? createdAt,
}) {
  return UserModel(
    userId: id,
    email: '$id@test.com',
    fullName: name,
    phoneNumber: '+255700000002',
    role: UserRole.buyer,
    isActive: active,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(List<UserModel> buyers, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      adminAllBuyersProvider.overrideWith(
        (ref) => Stream.value(buyers),
      ),
    ],
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
      home: const ManageBuyersScreen(),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets(
    'Manage Buyers — chips render localized labels in English',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap([_buyer(id: 'b1', name: 'Asha', active: true)]));
      await _settle(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.filterAll), findsOneWidget);
      expect(find.text(l10n.filterActive), findsOneWidget);
      expect(find.text(l10n.suspendedBadge), findsOneWidget);

      // The chips are rendered through `_BuyerStatusChip` widgets;
      // confirm they appear inside InkWell tap targets (so they are
      // real interactive chips, not stray text labels).
      expect(
        find.ancestor(
          of: find.text(l10n.filterAll),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Manage Buyers — chips render localized labels in Kiswahili',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap([_buyer(id: 'b1', name: 'Asha', active: true)],
            locale: const Locale('sw')),
      );
      await _settle(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('sw'));

      expect(find.text(l10n.filterAll), findsOneWidget);
      expect(find.text(l10n.filterActive), findsOneWidget);
      expect(find.text(l10n.suspendedBadge), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Buyers — search with no matches renders the localized empty state',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final buyers = [
        _buyer(id: 'b1', name: 'Asha Buyer', active: true),
        _buyer(id: 'b2', name: 'Salim Buyer', active: true),
      ];

      await tester.pumpWidget(_wrap(buyers));
      await _settle(tester);

      // Type a query that matches nothing.
      await tester.enterText(find.byType(TextField), 'zzzzzzz');
      await _settle(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.noMatchingBuyers), findsOneWidget);
      expect(find.text('Asha Buyer'), findsNothing);
      expect(find.text('Salim Buyer'), findsNothing);

      // Clear query — buyers return.
      await tester.enterText(find.byType(TextField), '');
      await _settle(tester);
      expect(find.text('Asha Buyer'), findsOneWidget);
      expect(find.text('Salim Buyer'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage Buyers — suspended buyers drop to the bottom of the visual stack',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Older active + newer suspended — without the sort the
      // suspended row would visually appear first (createdAt DESC).
      final buyers = [
        _buyer(
          id: 'b-old-active',
          name: 'Older Active',
          active: true,
          createdAt: DateTime(2025, 1, 1),
        ),
        _buyer(
          id: 'b-new-suspended',
          name: 'Newer Suspended',
          active: false,
          createdAt: DateTime(2026, 6, 1),
        ),
      ];

      await tester.pumpWidget(_wrap(buyers));
      await _settle(tester);

      // Active buyer must appear before suspended buyer in tree order.
      final activeY = tester.getTopLeft(find.text('Older Active')).dy;
      final suspendedY =
          tester.getTopLeft(find.text('Newer Suspended')).dy;

      expect(
        activeY,
        lessThan(suspendedY),
        reason: 'Active buyer should render above suspended buyer',
      );
    },
  );

  testWidgets(
    'Manage Buyers — pull-to-refresh works even when the filtered list is empty',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final buyers = [
        _buyer(id: 'b1', name: 'Asha Buyer', active: true),
      ];

      await tester.pumpWidget(_wrap(buyers));
      await _settle(tester);

      // Apply a query that hides the only buyer.
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await _settle(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.noMatchingBuyers), findsOneWidget);

      // AlwaysScrollableScrollPhysics means we can still pull down
      // to refresh even though the visible list is empty.
      final listFinder = find.byType(Scrollable).first;
      await tester.fling(listFinder, const Offset(0, 300), 1000);
      await tester.pump();
      await _settle(tester);

      // After the refresh delay (300ms in the screen code), the
      // buyer should still be present once the query is cleared —
      // and importantly the screen did not crash from a missing
      // scrollable physics.
      await tester.enterText(find.byType(TextField), '');
      await _settle(tester);
      expect(find.text('Asha Buyer'), findsOneWidget);
    },
  );
}
