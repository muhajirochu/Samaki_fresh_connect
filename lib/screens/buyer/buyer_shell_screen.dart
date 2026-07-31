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
import '../../providers/cart_provider.dart';
import '../common/my_orders_screen.dart';
import '../common/settings_screen.dart';
import 'buyer_dashboard_screen.dart';
import 'buyer_fish_search_screen.dart';
import 'cart_screen.dart';

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
    // autofocus: false — IndexedStack builds every tab at startup, so
    // the default (focus on build) would raise the keyboard while the
    // buyer is still on Home.
    BuyerFishSearchScreen(autofocus: false),
    CartScreen(),
    MyOrdersScreen(),
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
    final cartCount = ref.watch(cartCountProvider);

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
        // Swahili words ("Mipango", "Maagizo") from being clipped.
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
            icon: Badge(
              // Hidden at zero so an empty cart shows a clean icon.
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: Icon(Icons.shopping_cart_rounded, color: cs.primary),
            ),
            label: l10n.cart,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: cs.primary),
            label: l10n.orders,
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
