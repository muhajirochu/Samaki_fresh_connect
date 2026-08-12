// Buyer — Shell with a bottom NavigationBar.
//
// Wraps the five main buyer destinations:
//   0. Home     → BuyerDashboardScreen
//   1. Search   → BuyerFishSearchScreen
//   2. Cart     → CartScreen          (badged with the item count)
//   3. Orders   → MyOrdersScreen
//   4. Settings → SettingsScreen
//
// Follows the same shape as `AdminShellScreen`: an IndexedStack so
// each tab keeps its scroll position and state when the buyer switches
// away and back. Every child owns its own Scaffold + AppBar.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../common/my_orders_screen.dart';
import '../common/profile_screen.dart';
import 'buyer_active_order_tab.dart';
import 'buyer_dashboard_screen.dart';
import 'buyer_fish_search_screen.dart';

class BuyerShellScreen extends ConsumerStatefulWidget {
  /// Pass an initial tab index when deep-linking into a specific tab.
  final int initialIndex;

  const BuyerShellScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<BuyerShellScreen> createState() => _BuyerShellScreenState();
}

class _BuyerShellScreenState extends ConsumerState<BuyerShellScreen> {
  late int _currentIndex;

  static const _screens = [
    BuyerDashboardScreen(),
    BuyerFishSearchScreen(autofocus: false),
    MyOrdersScreen(),
    BuyerActiveOrderTab(),
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
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: cs.primary),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded, color: cs.primary),
            label: l10n.search,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: cs.primary),
            label: l10n.orders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: cs.primary),
            label: l10n.trackOrder,
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
