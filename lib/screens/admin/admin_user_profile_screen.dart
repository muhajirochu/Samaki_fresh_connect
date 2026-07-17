// Admin — User profile deep view.
//
// Shared by sellers and buyers via the `/admin/users/:userId` route.
// Renders identity, role-specific fields, status (approved /
// suspended) and approver / suspension audit info. Footer has
// role-conditional admin actions.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class AdminUserProfileScreen extends ConsumerWidget {
  final String userId;
  const AdminUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.watch(adminAllUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.viewProfile)),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.loadingError(e.toString()))),
        data: (users) {
          UserModel? user;
          for (final u in users) {
            if (u.userId == userId) {
              user = u;
              break;
            }
          }
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingXL),
                child: Text(l10n.notLoggedIn),
              ),
            );
          }
          return _ProfileBody(user: user);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserModel user;
  const _ProfileBody({required this.user});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Color _statusColor(BuildContext context) {
    if (!user.isActive) return AppColors.errorRed;
    if (user.role == UserRole.streetSeller && !user.isApproved) {
      return AppColors.accentOrange;
    }
    return AppColors.accentGreen;
  }

  String _statusLabel(AppLocalizations l10n) {
    if (!user.isActive) return l10n.suspendedBadge;
    if (user.role == UserRole.streetSeller && !user.isApproved) {
      return l10n.pendingApprovalBadge;
    }
    return l10n.approvedBadge;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initials = _initials(user.fullName);
    final showPhoto =
        user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty;
    final statusColor = _statusColor(context);
    final statusLabel = _statusLabel(l10n);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingLG,
          AppSizes.paddingLG,
          AppSizes.paddingLG,
          AppSizes.paddingXXL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                    backgroundImage: showPhoto
                        ? NetworkImage(user.profilePictureUrl!)
                        : null,
                    child: showPhoto
                        ? null
                        : Text(
                            initials,
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Text(
                    user.fullName,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(user.email,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      )),
                  const SizedBox(height: AppSizes.paddingSM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingLG),

            // ── Identity card ─────────────────────────────────────
            _Section(
              title: l10n.accountInfo,
              children: [
                _Row(label: l10n.fullName, value: user.fullName),
                _Row(label: l10n.email, value: user.email),
                _Row(label: l10n.phone, value: user.phoneNumber),
                _Row(
                  label: l10n.account,
                  value: user.role.displayName,
                ),
              ],
            ),

            if (user.role == UserRole.streetSeller) ...[
              const SizedBox(height: AppSizes.paddingLG),
              _Section(
                title: l10n.sellerProfile,
                children: [
                  _Row(
                    label: l10n.market,
                    value: user.fishMarketName ?? '—',
                  ),
                  _Row(
                    label: l10n.activeListingsCount(user.totalListings),
                    value: l10n.ordersCount(user.totalOrders),
                  ),
                  if (user.totalSales > 0)
                    _Row(
                      label: l10n.platformRevenue,
                      value: 'TZS ${user.totalSales.toStringAsFixed(0)}',
                    ),
                ],
              ),
            ],

            const SizedBox(height: AppSizes.paddingLG),

            // ── Admin actions ─────────────────────────────────────
            _AdminActionsCard(user: user),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: AppSizes.paddingSM),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.60),
                  fontWeight: FontWeight.w600,
                )),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

class _AdminActionsCard extends ConsumerWidget {
  final UserModel user;
  const _AdminActionsCard({required this.user});

  Future<void> _confirmSuspend(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final reasonCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.suspendDialog),
        content: TextField(
          controller: reasonCtl,
          decoration: InputDecoration(
            labelText: l10n.suspendReason,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: Text(l10n.suspendUserAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await adminSuspendUser(ref, user.userId,
        reason: reasonCtl.text.trim());
    if (context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isSeller = user.role == UserRole.streetSeller;
    final canApprove = isSeller && !user.isApproved;
    final canRevoke = isSeller && user.isApproved;
    final canSuspend = user.isActive;
    final canReactivate = !user.isActive;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: AppColors.errorRed.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.adminActionsSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.errorRed,
                ),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          if (canApprove)
            _ActionButton(
              label: l10n.approveSeller,
              icon: Icons.verified_rounded,
              color: AppColors.accentGreen,
              onPressed: () async {
                await adminApproveSeller(ref, user.userId);
                if (context.mounted) Navigator.of(context).maybePop();
              },
            ),
          if (canRevoke)
            _ActionButton(
              label: l10n.revokeApproval,
              icon: Icons.block_rounded,
              color: AppColors.accentOrange,
              onPressed: () async {
                await adminRevokeSellerApproval(ref, user.userId);
                if (context.mounted) Navigator.of(context).maybePop();
              },
            ),
          if (canSuspend)
            _ActionButton(
              label: l10n.suspendUserAction,
              icon: Icons.lock_rounded,
              color: AppColors.errorRed,
              onPressed: () => _confirmSuspend(context, ref),
            ),
          if (canReactivate)
            _ActionButton(
              label: l10n.reactivateUser,
              icon: Icons.lock_open_rounded,
              color: AppColors.accentGreen,
              onPressed: () async {
                await adminReactivateUser(ref, user.userId);
                if (context.mounted) Navigator.of(context).maybePop();
              },
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: Icon(icon),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}