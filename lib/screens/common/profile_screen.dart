// Profile screen — premium version.
//
// Layout:
//   1. Hero header with avatar + name + role chip (gradient bg)
//   2. Quick actions grid
//   3. Account info card
//   4. Appearance card
//   5. Logout button
//
// Reads all colours from `Theme.of(context)` / `AppGradients.of(context)`
// so it renders correctly in both light and dark themes.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/premium_components.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/settings/theme_switcher_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(currentUserStreamProvider);
    final cs = Theme.of(context).colorScheme;
    final gradients = AppGradients.of(context);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.myProfile, style: tt.titleLarge),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: cs.primary),
            tooltip: l10n.editProfile,
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text(l10n.loadingError(e.toString()))),
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.notLoggedIn));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingXXL),
            child: Column(
              children: [
                // ── Hero header ────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: gradients.brand,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSizes.radiusXL),
                      bottomRight: Radius.circular(AppSizes.radiusXL),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.paddingXXL,
                    horizontal: AppSizes.paddingLG,
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 4,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            backgroundImage: user.profilePictureUrl != null
                                ? NetworkImage(user.profilePictureUrl!)
                                : null,
                            child: user.profilePictureUrl == null
                                ? Text(
                                    _initialsFor(user.fullName),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -1.0,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLG),
                      Text(
                        user.fullName,
                        style: tt.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMD,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.role.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLG),

                // ── Quick actions grid ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLG),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.shopping_bag_rounded,
                              label: l10n.myOrders,
                              color: cs.primary,
                              onTap: () => context.push('/orders'),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSM),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.favorite_rounded,
                              label: l10n.wishlist,
                              // Wishlist uses tertiary (amber/teal)
                              // so it visually differs from the
                              // primary-coloured "My Orders" tile.
                              color: cs.tertiary,
                              onTap: () => context.push('/buyer/wishlist'),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSM),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.notifications_rounded,
                              label: l10n.notifications,
                              // Notifications also uses tertiary so
                              // the three quick-action tiles share
                              // the brand palette without duplicating
                              // colours.
                              color: cs.tertiary,
                              onTap: () => context.push('/buyer/notifications'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLG),

                // ── Appearance Section ─────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Appearance',
                        subtitle: 'Switch between Light and Dark',
                        leadingIcon: Icons.palette_rounded,
                      ),
                      SizedBox(height: AppSizes.paddingMD),
                      ThemeSwitcherTile(),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLG),

                // ── Account info ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Account Information',
                        leadingIcon: Icons.person_rounded,
                      ),
                      const SizedBox(height: AppSizes.paddingMD),
                      PremiumCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ProfileInfoTile(
                              icon: Icons.email_rounded,
                              title: 'Email',
                              subtitle: user.email,
                              showDivider: true,
                            ),
                            _ProfileInfoTile(
                              icon: Icons.phone_rounded,
                              title: 'Phone Number',
                              subtitle: user.phoneNumber,
                              showDivider: true,
                            ),
                            _ProfileInfoTile(
                              icon: Icons.location_on_rounded,
                              title: 'Location',
                              subtitle: (user.location != null &&
                                      user.location!['latitude'] != null &&
                                      user.location!['longitude'] != null)
                                  ? '${user.location!['latitude']}, ${user.location!['longitude']}'
                                  : 'Not specified',
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXXL),
                      OutlinedButton.icon(
                        // Single source of truth — delegates to the
                        // AuthController notifier. The router's
                        // redirect picks up the auth-state flip via
                        // authRefreshProvider and lands the user
                        // on /login; no imperative context.go here.
                        onPressed: () => ref
                            .read(authControllerProvider.notifier)
                            .signOut(),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(l10n.logout),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(
                              color: cs.error.withValues(alpha: 0.5)),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLG),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: AppSizes.fontMD,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXL),
                      Center(
                        child: Text(
                          'Samaki Fresh Connect v1.0',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.paddingMD,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showDivider;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = BackgroundStyle.of(context);
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: AppSizes.paddingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.60),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 20,
            color: bg.border,
          ),
      ],
    );
  }
}