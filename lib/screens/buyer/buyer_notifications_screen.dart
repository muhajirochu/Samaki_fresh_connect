// Buyer notifications screen. Lists every cloud notification for the
// current buyer, newest first. Tapping an item marks it read and
// navigates to the related entity (fish listing / seller map / etc).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/notification_type.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/common/app_bar_actions_bar.dart';

class BuyerNotificationsScreen extends ConsumerWidget {
  const BuyerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Arifa'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => ref
                .read(buyerNotificationControllerProvider.notifier)
                .markAllAsRead(),
            child: Text(
              'Weka zote zimesomwa',
              style: TextStyle(color: cs.onPrimary, fontSize: 12),
            ),
          ),
          // Theme switcher (visible across all buyer-facing screens so
          // the user can flip White / Cream / Dark without leaving
          // their current context).
          const AppBarActionsBar(showNotifications: false),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hitilafu: $e')),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingSM,
              ),
              itemCount: list.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: cs.outline.withValues(alpha: 0.15),
                indent: AppSizes.paddingMD,
                endIndent: AppSizes.paddingMD,
              ),
              itemBuilder: (context, i) => _NotificationTile(
                item: list[i],
                onTap: () => _onTap(context, ref, list[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, NotificationItem n) {
    ref
        .read(buyerNotificationControllerProvider.notifier)
        .markAsRead(n.id);
    final related = n.relatedId;
    if (related == null) return;
    switch (n.type) {
      case NotificationType.fishAvailableNow:
      case NotificationType.newSellerHasFish:
        context.push('/buyer/map?q=$related');
        break;
      case NotificationType.requestAccepted:
      case NotificationType.requestRejected:
      case NotificationType.requestOffered:
        context.push('/orders');
        break;
      case NotificationType.orderStatusChanged:
        context.push('/orders/$related');
        break;
      case NotificationType.generic:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tileColor = item.isRead
        ? cs.surface
        : cs.primary.withValues(alpha: 0.06);
    return Material(
      color: tileColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMD,
            vertical: AppSizes.paddingMD,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeAvatar(type: item.type),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(item.createdAt),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.70),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 6, top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'sasa hivi';
    if (d.inMinutes < 60) return '${d.inMinutes} dk';
    if (d.inHours < 24) return '${d.inHours} saa';
    if (d.inDays < 7) return '${d.inDays} siku';
    return '${t.day}/${t.month}';
  }
}

class _TypeAvatar extends StatelessWidget {
  final NotificationType type;
  const _TypeAvatar({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(type);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      ),
      child: Center(
        child: Text(type.emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Color _colorFor(NotificationType t) {
    switch (t) {
      case NotificationType.requestAccepted:
        return AppColors.successGreen;
      case NotificationType.requestRejected:
        return AppColors.errorRed;
      case NotificationType.requestOffered:
        return AppColors.infoBlue;
      case NotificationType.fishAvailableNow:
      case NotificationType.newSellerHasFish:
        return AppColors.accentOrange;
      case NotificationType.orderStatusChanged:
        return AppColors.secondaryTeal;
      case NotificationType.generic:
        return AppColors.gray500;
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                    color: cs.outline.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              child: Icon(Icons.notifications_off_rounded,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: AppSizes.paddingMD),
            Text(
              'Hakuna arifa bado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              'Arifa za maombi yako, samaki wapya, na '
              'maendeleo ya oda zitaonekana hapa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
