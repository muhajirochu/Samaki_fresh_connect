// In-app banner that listens to `wishlistMatchEventsProvider` and pops
// a SnackBar whenever a wishlist match fires. Mount this once near the
// top of the buyer shell.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../providers/notification_provider.dart';

class WishlistMatchBanner extends ConsumerWidget {
  const WishlistMatchBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the stream causes the widget to rebuild on every event;
    // the post-frame callback surfaces the banner once per change.
    ref.listen<AsyncValue<WishlistMatch?>>(
      wishlistMatchEventsProvider,
      (_, next) {
        final match = next.valueOrNull;
        if (match == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🐟 ${match.item.displayName} sasa inapatikana karibu nawe!',
              ),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      },
    );
    return const SizedBox.shrink();
  }
}