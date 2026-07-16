// Buyer wishlist screen. Lists fish types the buyer is hunting for.
// Tapping the trash icon removes the entry. Tapping the row jumps to
// the map filtered by that fish type.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/enums/fish_type.dart';
import '../../models/wishlist_model.dart';
import '../../providers/notification_provider.dart';

class BuyerWishlistScreen extends ConsumerWidget {
  const BuyerWishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Orodha ya Matakwa'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      body: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hitilafu: $e')),
        data: (list) {
          if (list.isEmpty) {
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
                      child: Icon(Icons.favorite_border_rounded,
                          size: 56,
                          color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    Text(
                      'Orodha yako ni tupu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),
                    Text(
                      'Ukiongeza samaki unayotafuta, tutakuarifu mara '
                      'itakapopatikana karibu nawe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.65),
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSM),
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: cs.outline.withValues(alpha: 0.15),
              indent: AppSizes.paddingMD,
              endIndent: AppSizes.paddingMD,
            ),
            itemBuilder: (context, i) {
              final entry = list[i];
              return _WishlistTile(
                entry: entry,
                onTap: () => context.push(
                    '/buyer/map?fishType=${entry.fishType.value}'),
                onRemove: () => ref
                    .read(wishlistControllerProvider.notifier)
                    .remove(entry.fishType),
              );
            },
          );
        },
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _WishlistTile({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          child: const Icon(Icons.favorite_rounded,
              color: AppColors.accentOrange),
        ),
        title: Text(
          entry.fishType.displayName,
          style: TextStyle(
              fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        subtitle: Text(
          entry.maxPricePerKg == null
              ? 'Arifu utakapopata'
              : 'Hadi ${entry.maxPricePerKg!.toStringAsFixed(0)} TZS/kg',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.65),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.errorRed),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
