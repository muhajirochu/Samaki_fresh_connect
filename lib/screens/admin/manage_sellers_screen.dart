// Admin — Manage Street Sellers.
//
// Premium list of every user with role `streetSeller`. Tapping a row
// opens a drawer with two actions: View profile (full user doc) and
// Block / Unblock (toggles `isActive`). The list is reactive — new
// sellers pop in live, blocked sellers drop to the bottom of the
// visual stack via a tinted treatment.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class ManageSellersScreen extends ConsumerWidget {
  const ManageSellersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sellersAsync = ref.watch(adminAllUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageStreetSellers),
      ),
      body: sellersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.loadingError(e.toString()))),
        data: (allUsers) {
          final sellers = allUsers
              .where((u) => u.role.name == 'streetSeller')
              .toList(growable: false);
          if (sellers.isEmpty) {
            return _EmptyState(
              icon: Icons.storefront_rounded,
              title: l10n.noStreetSellers,
              subtitle: l10n.noStreetSellersSubtitle,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminAllUsersProvider);
              await Future<void>.delayed(
                const Duration(milliseconds: 300),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              itemCount: sellers.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSizes.paddingMD),
              itemBuilder: (_, i) =>
                  _SellerCard(seller: sellers[i], key: ValueKey(sellers[i].userId)),
            ),
          );
        },
      ),
    );
  }
}

class _SellerCard extends ConsumerWidget {
  final UserModel seller;
  const _SellerCard({required this.seller, super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _confirmToggleBlock(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final isBlocked = !seller.isActive;
    final shouldToggle = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBlocked ? l10n.unblockUser : l10n.blockUser),
        content: Text(l10n.confirmBlockUser),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: Text(
              isBlocked ? l10n.unblockUser : l10n.blockUser,
            ),
          ),
        ],
      ),
    );
    if (shouldToggle != true) return;
    final service = ref.read(adminUserServiceProvider);
    try {
      await service.setUserActive(seller.userId, isBlocked);
      ref.invalidate(adminAllUsersProvider);
      ref.invalidate(adminUserCountsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBlocked ? l10n.userUnblocked : l10n.userBlocked,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final initials = _initials(seller.fullName);
    final isBlocked = !seller.isActive;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: isBlocked
              ? AppColors.errorRed.withValues(alpha: 0.45)
              : cs.outline.withValues(alpha: 0.30),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isBlocked
                  ? AppColors.errorRed.withValues(alpha: 0.12)
                  : cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                color: isBlocked ? AppColors.errorRed : cs.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.fullName,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  seller.email,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (isBlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.blockUser.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        seller.phoneNumber,
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.viewProfile,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'block') _confirmToggleBlock(context, ref);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      isBlocked
                          ? Icons.lock_open_rounded
                          : Icons.block_rounded,
                      size: 18,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBlocked ? l10n.unblockUser : l10n.blockUser,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: cs.primary),
            ),
            const SizedBox(height: AppSizes.paddingLG),
            Text(
              title,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              subtitle,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
