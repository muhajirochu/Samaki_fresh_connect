// Buyer requests screen — lists every FishRequest owned by the current
// buyer and provides a Cancel action. Streams from
// `buyerActiveRequestsProvider` (active) plus a fresh-stream for all
// statuses so the user can see history too.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/fish_request_model.dart';
import '../../providers/buyer_provider.dart';

class BuyerRequestsScreen extends ConsumerStatefulWidget {
  const BuyerRequestsScreen({super.key});

  @override
  ConsumerState<BuyerRequestsScreen> createState() =>
      _BuyerRequestsScreenState();
}

class _BuyerRequestsScreenState extends ConsumerState<BuyerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We watch ALL requests here, then filter by tab in the body. Using
    // the active-only provider would have hidden the recently-cancelled
    // items that the user wants to confirm.
    final session = ref.watch(currentBuyerSessionProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Maombi Yangu')),
        body: const Center(child: Text('Please sign in as a buyer')),
      );
    }
    final allAsync = ref.watch(buyerAllRequestsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Maombi Yangu',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final active = all
              .where((r) =>
                  r.status == FishRequestStatus.open ||
                  r.status == FishRequestStatus.offered)
              .toList();
          final history = all
              .where((r) =>
                  r.status == FishRequestStatus.cancelled ||
                  r.status == FishRequestStatus.accepted ||
                  r.status == FishRequestStatus.fulfilled ||
                  r.status == FishRequestStatus.expired)
              .toList();
          return TabBarView(
            controller: _tab,
            children: [
              _RequestsList(requests: active, isActive: true),
              _RequestsList(requests: history, isActive: false),
            ],
          );
        },
      ),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  final List<FishRequestModel> requests;
  final bool isActive;
  const _RequestsList({required this.requests, required this.isActive});

  Future<void> _cancel(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLG)),
        title: const Text('Cancel request?'),
        content: const Text(
          'Sellers will no longer see this request. You can submit a new '
          'one any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(buyerDashboardControllerProvider.notifier)
        .cancelFishRequest(id);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Request cancelled'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.gray200, width: 1.5),
                ),
                child: Icon(
                  isActive
                      ? Icons.send_rounded
                      : Icons.history_rounded,
                  size: 56,
                  color: AppColors.gray400,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              Text(
                isActive ? 'No active requests' : 'No history yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray700,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                isActive
                    ? 'Send a request from the map and sellers will see it.'
                    : 'Past accepted, cancelled and completed requests will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.gray600, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      itemCount: requests.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSizes.paddingSM),
      itemBuilder: (context, i) =>
          _RequestTile(request: requests[i], onCancel: _cancel),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final FishRequestModel request;
  final Future<void> Function(BuildContext, WidgetRef, String) onCancel;
  const _RequestTile({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusColor, statusLabel) = _statusVisuals(request.status);
    final cancellable =
        request.status == FishRequestStatus.open ||
            request.status == FishRequestStatus.offered;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Icon(Icons.set_meal_rounded, color: statusColor),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.quantityKg.toStringAsFixed(1)} kg · '
                        '${_relativeTime(request.createdAt)}',
                        style: const TextStyle(
                            color: AppColors.gray600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSM, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                request.notes!,
                style: const TextStyle(
                    color: AppColors.gray700, fontSize: 13),
              ),
            ],
            if (request.offersCount > 0) ...[
              const SizedBox(height: AppSizes.paddingSM),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: AppColors.infoBlue),
                  const SizedBox(width: 4),
                  Text(
                    '${request.offersCount} offer${request.offersCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.infoBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (cancellable) ...[
              const SizedBox(height: AppSizes.paddingSM),
              const Divider(height: 1, color: AppColors.gray100),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onCancel(context, ref, request.requestId),
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.errorRed, size: 18),
                  label: const Text(
                    'Cancel request',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, String) _statusVisuals(FishRequestStatus s) {
    switch (s) {
      case FishRequestStatus.open:
        return (AppColors.infoBlue, 'Open');
      case FishRequestStatus.offered:
        return (AppColors.accentOrange, 'Offers');
      case FishRequestStatus.accepted:
        return (AppColors.successGreen, 'Accepted');
      case FishRequestStatus.fulfilled:
        return (AppColors.successGreen, 'Done');
      case FishRequestStatus.cancelled:
        return (AppColors.errorRed, 'Cancelled');
      case FishRequestStatus.expired:
        return (AppColors.gray500, 'Expired');
    }
  }

  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day}/${t.month}';
  }
}