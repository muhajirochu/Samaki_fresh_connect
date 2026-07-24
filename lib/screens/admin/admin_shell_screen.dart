// Admin — Shell with BottomNavigationBar.
//
// Wraps the four main admin destinations:
//   0. Home          → AdminDashboardScreen
//   1. All Listings  → AdminAllListingsScreen
//   2. Categories    → FishCategoriesScreen
//   3. Settings      → AdminSettingsScreen
//
// The shell uses IndexedStack so each tab keeps its state when
// switching back and forth.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'admin_dashboard_screen.dart';
import 'admin_settings_screen.dart';
import 'fish_categories_screen.dart';
import 'admin_all_listings_screen.dart';

class AdminShellScreen extends StatefulWidget {
  /// Pass an initial tab index when deep-linking into a specific tab.
  final int initialIndex;

  const AdminShellScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late int _currentIndex;

  static const _screens = [
    AdminDashboardScreen(),
    AdminAllListingsScreen(),
    FishCategoriesScreen(),
    AdminSettingsScreen(),
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
      // Each child screen owns its own Scaffold / AppBar.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: cs.surface,
        indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.15),
        shadowColor: cs.shadow,
        elevation: 4,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded,
                color: AppColors.primaryBlue),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt_rounded,
                color: AppColors.primaryBlue),
            label: l10n.allListings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category_rounded,
                color: AppColors.primaryBlue),
            label: l10n.manageCategories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded,
                color: AppColors.primaryBlue),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
