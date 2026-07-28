// Admin — Manage Buyers.
//
// Live list of every user with role `buyer`. Search by name /
// email / phone. Per-row actions: View Profile, Suspend,
// Reactivate. The list is reactive — new buyers pop in live,
// suspended buyers drop to the bottom of the visual stack via a
// tinted treatment.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class ManageBuyersScreen extends ConsumerStatefulWidget {
  const ManageBuyersScreen({super.key});

  @override
  ConsumerState<ManageBuyersScreen> createState() => _ManageBuyersScreenState();
}

class _ManageBuyersScreenState extends ConsumerState<ManageBuyersScreen> {
  String _query = '';
  String _statusFilter = 'all'; // 'all' | 'active' | 'suspended'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buyersAsync = ref.watch(adminAllBuyersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageBuyers)),
      body: buyersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.loadingError(e.toString()))),
        data: (buyers) {
          final filteredByQuery = _query.isEmpty
              ? buyers
              : buyers.where((u) {
                  final q = _query.toLowerCase();
                  return u.fullName.toLowerCase().contains(q) ||
                      u.email.toLowerCase().contains(q) ||
                      u.phoneNumber.toLowerCase().contains(q);
                }).toList();

          // Apply status filter. Admins reach for this when triaging
          // abuse reports — pick "Suspended" to find the offenders in
          // one tap, "Active" to find the normal cohort.
          final filtered = filteredByQuery.where((u) {
            switch (_statusFilter) {
              case 'suspended':
                return !u.isActive;
              case 'active':
                return u.isActive;
              case 'all':
              default:
                return true;
            }
          }).toList();

          if (buyers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingXL),
                child: Text(
                  l10n.noBuyersRegistered,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }

          // Sort: active buyers first (most recent), then suspended
          // buyers at the bottom — matches the doc comment at the
          // top of the file and keeps the moderation signal obvious
          // when triaging abuse reports.
          final sorted = [...filtered]..sort((a, b) {
              if (a.isActive == b.isActive) {
                return b.createdAt.compareTo(a.createdAt);
              }
              return a.isActive ? -1 : 1;
            });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: l10n.searchBuyers,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _BuyerStatusChip(
                            label: l10n.filterAll,
                            selected: _statusFilter == 'all',
                            onTap: () =>
                                setState(() => _statusFilter = 'all'),
                          ),
                          const SizedBox(width: AppSizes.paddingSM),
                          _BuyerStatusChip(
                            label: l10n.filterActive,
                            selected: _statusFilter == 'active',
                            onTap: () =>
                                setState(() => _statusFilter = 'active'),
                          ),
                          const SizedBox(width: AppSizes.paddingSM),
                          _BuyerStatusChip(
                            label: l10n.suspendedBadge,
                            selected: _statusFilter == 'suspended',
                            onTap: () =>
                                setState(() => _statusFilter = 'suspended'),
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
                    ref.invalidate(adminAllBuyersProvider);
                    await Future<void>.delayed(
                        const Duration(milliseconds: 300));
                  },
                  // AlwaysScrollable so the RefreshIndicator fires
                  // even when the filtered list is empty or short —
                  // the user can still pull-to-refresh after applying
                  // a filter that hides everyone.
                  child: sorted.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.paddingLG,
                            AppSizes.paddingXL,
                            AppSizes.paddingLG,
                            AppSizes.paddingLG,
                          ),
                          children: [
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppSizes.paddingXL),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: AppSizes.paddingMD),
                                    Text(
                                      l10n.noMatchingBuyers,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.paddingLG,
                            0,
                            AppSizes.paddingLG,
                            AppSizes.paddingLG,
                          ),
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSizes.paddingMD),
                          itemBuilder: (_, i) => _BuyerCard(
                            buyer: sorted[i],
                            key: ValueKey(sorted[i].userId),
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

class _BuyerCard extends ConsumerWidget {
  final UserModel buyer;
  const _BuyerCard({required this.buyer, super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final initials = _initials(buyer.fullName);
    final isSuspended = !buyer.isActive;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: isSuspended
            ? AppColors.errorRed.withValues(alpha: 0.04)
            : cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: isSuspended
              ? AppColors.errorRed.withValues(alpha: 0.45)
              : cs.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(initials,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                )),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(buyer.fullName,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(buyer.email,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (isSuspended)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.suspendedBadge.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.viewProfile,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) async {
              if (v == 'view') {
                // Use go_router so the screen mounts inside the
                // same navigator as the rest of the admin module.
                context.push('/admin/users/${buyer.userId}');
              } else if (v == 'toggle') {
                final messenger = ScaffoldMessenger.of(context);
                final l10nAction = AppLocalizations.of(context);
                try {
                  if (isSuspended) {
                    // ignore: use_build_context_synchronously
                    await adminReactivateUser(context, buyer.userId);
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10nAction.userReactivated),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    // ignore: use_build_context_synchronously
                    await adminSuspendUser(context, buyer.userId);
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10nAction.userSuspended),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (_) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10nAction.userModerationFailed),
                      backgroundColor: AppColors.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                    isSuspended
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 18,
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(width: 8),
                  Text(isSuspended
                      ? l10n.reactivateUser
                      : l10n.blockUser),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuyerStatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BuyerStatusChip({
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
