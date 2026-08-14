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
import '../../providers/order_tracking_provider.dart';
import '../common/my_orders_screen.dart';
import '../common/profile_screen.dart';
import 'seller_active_delivery_tab.dart';
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
    MyOrdersScreen(),
    SellerActiveDeliveryTab(),
    ProfileScreen(),
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

    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final isApproved = user?.isApproved ?? false;
    final sellerId = user?.userId;
    final pending = sellerId == null
        ? 0
        : ref.watch(sellerPendingOrdersProvider(sellerId)).valueOrNull?.length ??
            0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (!isApproved && (i == 1 || i == 2)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Akaunti yako inasubiri kudhibitishwa na Admin kabla ya kuitumia.',
                ),
                backgroundColor: Color(0xFF0284C7),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          setState(() => _currentIndex = i);
        },
        backgroundColor: cs.surface,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        shadowColor: cs.shadow,
        elevation: 4,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: cs.primary),
            label: l10n.dashboard,
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
            icon: const Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: cs.primary),
            label: l10n.trackDeliveryTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: cs.primary),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
