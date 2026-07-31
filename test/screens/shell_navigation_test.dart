// Tests for the buyer and street-seller bottom navigation bars.
//
// These assert the thing the user actually asked for: that each role's
// shell shows exactly its five destinations, in order, and that
// tapping one switches tabs. They render at 360x640 so a regression
// that only breaks on a real phone is caught here rather than on a
// handset.
//
// Firebase is never initialised, so every provider the child screens
// watch resolves to its empty/guarded branch — which is precisely the
// first-paint state we want to prove does not throw.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/constants/app_colors.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/providers/locale_provider.dart';
import 'package:samakifresh_connect/providers/theme_provider.dart';
import 'package:samakifresh_connect/screens/buyer/buyer_fish_search_screen.dart';
import 'package:samakifresh_connect/screens/buyer/buyer_shell_screen.dart';
import 'package:samakifresh_connect/screens/street_seller/seller_shell_screen.dart';
import 'package:samakifresh_connect/widgets/dashboard/search_bar.dart';

const Size kSmallPhone = Size(360, 640);

/// Overrides the two providers that reach for `StorageService`, which
/// is not initialised in tests. Without these the theme notifier is
/// constructed, immediately throws on the storage read, and is then
/// disposed — surfacing as "used after being disposed" rather than the
/// real cause. Same override set as `theme_golden_test.dart`.
Widget _app(Widget shell, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      themeControllerProvider.overrideWith(
        (ref) => ThemeModeNotifier(AppThemeMode.light, ''),
      ),
      localeProvider.overrideWith(() => LocaleNotifier()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: shell,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget shell, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = kSmallPhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(shell, locale: locale));
  // pump, not pumpAndSettle: the child dashboards hold indeterminate
  // progress indicators that never settle.
  await tester.pump();
}

/// The labels of the NavigationBar's destinations, in order.
List<String> _destinationLabels(WidgetTester tester) {
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
  return bar.destinations
      .cast<NavigationDestination>()
      .map((d) => d.label)
      .toList();
}

void main() {
  group('BuyerShellScreen', () {
    testWidgets('shows the five buyer destinations in order', (tester) async {
      await _pump(tester, const BuyerShellScreen());

      expect(
        _destinationLabels(tester),
        ['Home', 'Search', 'Cart', 'Orders', 'Settings'],
      );
    });

    testWidgets('starts on Home and switches tab on tap', (tester) async {
      await _pump(tester, const BuyerShellScreen());

      NavigationBar bar() =>
          tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar().selectedIndex, 0);

      // Tap "Settings" — the last destination.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();

      expect(bar().selectedIndex, 4);
    });

    testWidgets('honours initialIndex for deep links', (tester) async {
      await _pump(tester, const BuyerShellScreen(initialIndex: 2));

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 2);
    });

    testWidgets('clamps an out-of-range initialIndex', (tester) async {
      // Guards against a deep link with a stale tab number crashing
      // the IndexedStack with a range error.
      await _pump(tester, const BuyerShellScreen(initialIndex: 99));

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 4);
    });

    testWidgets('renders on a 360x640 phone without overflow', (tester) async {
      await _pump(tester, const BuyerShellScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('the dashboard no longer carries its own search bar',
        (tester) async {
      // Search moved to the bottom nav's Search tab. The Home tab must
      // not ship a second search surface — that was the whole point of
      // removing the hero-section bar.
      await _pump(tester, const BuyerShellScreen());

      expect(find.byType(DashboardSearchBar), findsNothing);
    });

    testWidgets('passes autofocus: false to the Search tab', (tester) async {
      // IndexedStack builds every tab up front, so the Search tab's
      // initState runs at startup. Autofocusing there would raise the
      // keyboard over the Home tab.
      //
      // Asserted on the widget's property rather than on real focus
      // state: FocusNode.requestFocus inside a post-frame callback does
      // not reliably settle under the test binding, so a focus-based
      // assertion passes either way and proves nothing.
      await _pump(tester, const BuyerShellScreen());

      final search = tester.widget<BuyerFishSearchScreen>(
        find.byType(BuyerFishSearchScreen, skipOffstage: false),
      );
      expect(search.autofocus, isFalse);
    });

    testWidgets('hides the cart badge when the cart is empty', (tester) async {
      await _pump(tester, const BuyerShellScreen());

      // No signed-in buyer → cartCountProvider is 0 → badge hidden.
      final badges = tester.widgetList<Badge>(find.byType(Badge));
      expect(badges, isNotEmpty);
      expect(badges.every((b) => b.isLabelVisible == false), isTrue);
    });
  });

  group('SellerShellScreen', () {
    testWidgets('shows the five seller destinations in order', (tester) async {
      await _pump(tester, const SellerShellScreen());

      expect(
        _destinationLabels(tester),
        ['Dashboard', 'My Products', 'Orders', 'Messages', 'Settings'],
      );
    });

    testWidgets('starts on Dashboard and switches tab on tap', (tester) async {
      await _pump(tester, const SellerShellScreen());

      NavigationBar bar() =>
          tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar().selectedIndex, 0);

      await tester.tap(find.byIcon(Icons.forum_outlined));
      await tester.pump();

      expect(bar().selectedIndex, 3);
    });

    testWidgets('honours initialIndex for deep links', (tester) async {
      await _pump(tester, const SellerShellScreen(initialIndex: 1));

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 1);
    });

    testWidgets('renders on a 360x640 phone without overflow', (tester) async {
      await _pump(tester, const SellerShellScreen());
      expect(tester.takeException(), isNull);
    });
  });

  group('Swahili labels', () {
    testWidgets('buyer destinations are translated', (tester) async {
      await _pump(
        tester,
        const BuyerShellScreen(),
        locale: const Locale('sw'),
      );

      expect(
        _destinationLabels(tester),
        ['Mwanzo', 'Tafuta', 'Kikapu', 'Maagizo', 'Mipango'],
      );
    });

    testWidgets('seller destinations are translated', (tester) async {
      await _pump(
        tester,
        const SellerShellScreen(),
        locale: const Locale('sw'),
      );

      expect(
        _destinationLabels(tester),
        ['Dashibodi', 'Bidhaa Zangu', 'Maagizo', 'Ujumbe', 'Mipango'],
      );
    });
  });
}
