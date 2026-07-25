// Admin — Admin Settings.
//
// Admin-only hub. Inherits the personal sections (Appearance,
// Language, Account) from the standard SettingsScreen via
// composition, then exposes additional platform-level toggles
// only an admin can use (live data refresh).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/route_paths.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingLG,
          AppSizes.paddingLG,
          AppSizes.paddingLG,
          AppSizes.paddingXXL,
        ),
        children: [
          // ── Personal ─────────────────────────────────────────
          Text(l10n.settings,
              style: tt.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSizes.paddingSM),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.25),
              ),
            ),
            child: const _EmbeddedSettings(),
          ),
          const SizedBox(height: AppSizes.paddingXL),

          // ── Platform tools ───────────────────────────────────
          Text(l10n.adminOnlySection,
              style: tt.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSizes.paddingSM),
          _AdminToolTile(
            icon: Icons.refresh_rounded,
            title: l10n.refreshData,
            subtitle: l10n.refreshDataSubtitle,
            color: cs.primary,
            onTap: () {
              ref.invalidate(adminAllUsersProvider);
              ref.invalidate(adminAllSellersProvider);
              ref.invalidate(adminAllBuyersProvider);
              ref.invalidate(adminAllListingsProvider);
              ref.invalidate(adminAllOrdersProvider);
              ref.invalidate(adminAllCategoriesProvider);
              ref.invalidate(adminActiveCategoriesProvider);
              ref.invalidate(adminRecentActivityProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.settingsSaved),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.paddingMD),
          _AdminToolTile(
            icon: Icons.notifications_rounded,
            title: l10n.notifications,
            subtitle: l10n.notificationsPreferences,
            color: AppColors.accentOrange,
            onTap: () {},
          ),
          const SizedBox(height: AppSizes.paddingMD),
          _AdminToolTile(
            icon: Icons.info_rounded,
            title: l10n.aboutTitle,
            subtitle: l10n.appInfoAndCredits,
            color: AppColors.infoBlue,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// Embeds the personal Settings content (Appearance / Language /
/// Account) into the admin settings without re-mounting a Scaffold.
class _EmbeddedSettings extends StatelessWidget {
  const _EmbeddedSettings();

  @override
  Widget build(BuildContext context) {
    // We hand-roll the inner tiles here (rather than mounting the
    // full SettingsScreen) so the section header strip / appbar
    // duplication is avoided.
    return const Column(
      children: [
        // The personal profile / sign out / language / theme actions
        // can be reached from the Profile screen / TopAppBar, so
        // this embed stays minimal — a static link to that screen.
        _ExternalLinkTile(),
      ],
    );
  }
}

class _ExternalLinkTile extends StatelessWidget {
  const _ExternalLinkTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.person_rounded),
      title: Text(l10n.myProfile),
      subtitle: Text(l10n.editProfile),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () {
        context.pushNamed(AppRouteNames.settings);
      },
    );
  }
}

class _AdminToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    Text(subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        )),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
