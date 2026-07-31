// Street seller — Shell with a bottom NavigationBar.
//
// Wraps the five main seller destinations:
//   0. Dashboard   → StreetSellerDashboardScreen
//   1. My Products → MyListingsScreen
//   2. Orders      → MyOrdersScreen        (badged with pending count)
//   3. Messages    → SellerContactsScreen  (call / SMS your buyers)
//   4. Settings    → SettingsScreen
//
// Same IndexedStack shape as `AdminShellScreen` and
// `BuyerShellScreen`, so all three roles behave identically when
// switching tabs. Every child owns its own Scaffold + AppBar.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../common/my_listings_screen.dart';
import '../common/my_orders_screen.dart';
import '../common/settings_screen.dart';
import 'seller_contacts_screen.dart';
import 'street_seller_dashboard_screen.dart';

class SellerShellScreen extends ConsumerStatefulWidget {
  /// Pass an initial tab index when deep-linking into a specific tab.
  final int initialIndex;

  const SellerShellScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<SellerShellScreen> createState() => _SellerShellScreenState();
}

class _SellerShellScreenState extends ConsumerState<SellerShellScreen> {
  late int _currentIndex;

  static const _screens = [
    StreetSellerDashboardScreen(),
    MyListingsScreen(),
    MyOrdersScreen(),
    SellerContactsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    // Same pending-order signal the dashboard's "My Orders" tile
    // badges, surfaced on the nav bar so the seller sees it from any
    // tab. Resolves to 0 until the profile doc loads.
    final sellerId = ref.watch(currentUserStreamProvider).valueOrNull?.userId;
    final pending = sellerId == null
        ? 0
        : ref.watch(streetSellerPendingOrdersProvider(sellerId)).valueOrNull ??
            0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: cs.surface,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        shadowColor: cs.shadow,
        elevation: 4,
        // Five destinations on a 360dp phone leaves ~72dp per label.
        // Showing labels only for the selected tab keeps the longer
        // Swahili words ("Dashibodi", "Bidhaa Zangu") from clipping.
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: cs.primary),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded, color: cs.primary),
            label: l10n.myProducts,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: Icon(Icons.receipt_long_rounded, color: cs.primary),
            ),
            label: l10n.orders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded, color: cs.primary),
            label: l10n.messages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: cs.primary),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
