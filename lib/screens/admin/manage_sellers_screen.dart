// Admin — Manage Street Sellers (v2).
//
// Premium list of every user with role `streetSeller`. Search by
// name / email / phone, and per-row actions: View profile,
// Approve / Revoke approval, Suspend / Reactivate. The list is
// reactive via Firestore snapshots so new sellers pop in live
// and suspended sellers drop to the bottom of the visual stack
// via a tinted treatment.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class ManageSellersScreen extends ConsumerStatefulWidget {
  const ManageSellersScreen({super.key});

  @override
  ConsumerState<ManageSellersScreen> createState() =>
      _ManageSellersScreenState();
}

class _ManageSellersScreenState extends ConsumerState<ManageSellersScreen> {
  String _query = '';
  // Default to 'pending' so admins land on the most actionable
  // queue first — newly-registered sellers awaiting approval are
  // surfaced immediately rather than buried in the full list.
  String _statusFilter = 'pending'; // 'all' | 'pending' | 'approved' | 'suspended'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sellersAsync = ref.watch(adminAllSellersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageStreetSellers),
        actions: [
          // Pending-approval quick filter — admin opens this screen
          // most often to clear the queue of new sellers awaiting
          // review, so we put it one tap away in the AppBar.
          IconButton(
            tooltip: l10n.pendingApprovalBadge,
            icon: const Icon(Icons.schedule_rounded),
            onPressed: () => setState(() {
              _statusFilter = _statusFilter == 'pending' ? 'all' : 'pending';
            }),
          ),
        ],
      ),
      body: sellersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.loadingError(e.toString()))),
        data: (sellers) {
          final filteredByQuery = _query.isEmpty
              ? sellers
              : sellers.where((u) {
                  final q = _query.toLowerCase();
                  return u.fullName.toLowerCase().contains(q) ||
                      u.email.toLowerCase().contains(q) ||
                      u.phoneNumber.toLowerCase().contains(q);
                }).toList();

          // Apply status filter. The pending list is special-cased
          // so admins can see "inactive but pending approval"
          // accounts even after suspension.
          final filtered = filteredByQuery.where((u) {
            switch (_statusFilter) {
              case 'pending':
                return !u.isApproved;
              case 'suspended':
                return !u.isActive;
              case 'approved':
                return u.isApproved && u.isActive;
              case 'all':
              default:
                return true;
            }
          }).toList();

          if (sellers.isEmpty) {
            return _EmptyState(
              icon: Icons.storefront_rounded,
              title: l10n.noStreetSellers,
              subtitle: l10n.noStreetSellersSubtitle,
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: l10n.searchSellers,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    // Status filter chips — Pending / Approved /
                    // Suspended / All. The active chip is filled
                    // with the brand primary so the admin can
                    // spot the active filter at a glance.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusChip(
                            label: 'All',
                            selected: _statusFilter == 'all',
                            onTap: () => setState(() => _statusFilter = 'all'),
                          ),
                          const SizedBox(width: AppSizes.paddingSM),
                          _StatusChip(
                            label: l10n.pendingApprovalBadge,
                            selected: _statusFilter == 'pending',
                            onTap: () =>
                                setState(() => _statusFilter = 'pending'),
                          ),
                          const SizedBox(width: AppSizes.paddingSM),
                          _StatusChip(
                            label: l10n.approvedBadge,
                            selected: _statusFilter == 'approved',
                            onTap: () =>
                                setState(() => _statusFilter = 'approved'),
                          ),
                          const SizedBox(width: AppSizes.paddingSM),
                          _StatusChip(
                            label: l10n.suspendedBadge,
                            selected: _statusFilter == 'suspended',
                            onTap: () =>
                                setState(() => _statusFilter == 'suspended'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminAllSellersProvider);
                    await Future<void>.delayed(
                        const Duration(milliseconds: 300));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLG,
                      0,
                      AppSizes.paddingLG,
                      AppSizes.paddingLG,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.paddingMD),
                    itemBuilder: (_, i) => _SellerCard(
                      seller: filtered[i],
                      key: ValueKey(filtered[i].userId),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingSM,
        ),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l10n.suspendUserAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await adminSuspendUser(ref, seller.userId,
        reason: reasonCtl.text.trim());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initials = _initials(seller.fullName);
    final isSuspended = !seller.isActive;
    final isPendingApproval = !seller.isApproved;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        // Suspended rows get a faint error tint so the admin can
        // scan the list and spot them at a glance.
        color: isSuspended
            ? cs.error.withValues(alpha: 0.05)
            : cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: isSuspended
              ? cs.error.withValues(alpha: 0.45)
              : isPendingApproval
                  // Pending-approval border uses tertiary (amber on
                  // light / teal on dark) so it stands out without
                  // looking like an error.
                  ? cs.tertiary.withValues(alpha: 0.45)
                  : cs.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPendingApproval
                  ? cs.tertiary.withValues(alpha: 0.12)
                  : cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                color: isPendingApproval
                    ? cs.tertiary
                    : cs.primary,
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
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
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
                if (isSuspended)
                  _Badge(text: l10n.suspendedBadge, color: cs.error)
                else if (isPendingApproval)
                  _Badge(
                      text: l10n.pendingApprovalBadge,
                      color: cs.tertiary)
                else
                  _Badge(text: l10n.approvedBadge, color: cs.secondary),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) async {
              switch (v) {
                case 'view':
                  if (context.mounted) {
                    context.push('/admin/users/${seller.userId}');
                  }
                  break;
                case 'approve':
                  await adminApproveSeller(ref, seller.userId);
                  break;
                case 'revoke':
                  await adminRevokeSellerApproval(ref, seller.userId);
                  break;
                case 'suspend':
                  await _confirmSuspend(context, ref);
                  break;
                case 'reactivate':
                  await adminReactivateUser(ref, seller.userId);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'view',
                child: Row(children: [
                  const Icon(Icons.person_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.viewProfile),
                ]),
              ),
              if (!seller.isApproved)
                PopupMenuItem(
                  value: 'approve',
                  child: Row(children: [
                    Icon(Icons.verified_rounded,
                        size: 18, color: cs.secondary),
                    const SizedBox(width: 8),
                    Text(l10n.approveSeller),
                  ]),
                ),
              if (seller.isApproved)
                PopupMenuItem(
                  value: 'revoke',
                  child: Row(children: [
                    Icon(Icons.block_rounded,
                        size: 18, color: cs.tertiary),
                    const SizedBox(width: 8),
                    Text(l10n.revokeApproval),
                  ]),
                ),
              if (seller.isActive)
                PopupMenuItem(
                  value: 'suspend',
                  child: Row(children: [
                    Icon(Icons.lock_rounded,
                        size: 18, color: cs.error),
                    const SizedBox(width: 8),
                    Text(l10n.suspendUserAction),
                  ]),
                ),
              if (!seller.isActive)
                PopupMenuItem(
                  value: 'reactivate',
                  child: Row(children: [
                    Icon(Icons.lock_open_rounded,
                        size: 18, color: cs.secondary),
                    const SizedBox(width: 8),
                    Text(l10n.reactivateUser),
                  ]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
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