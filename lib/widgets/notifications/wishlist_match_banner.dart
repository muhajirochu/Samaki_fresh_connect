// In-app banner that listens to `wishlistMatchEventsProvider` and pops
// a SnackBar whenever a wishlist match fires. Mount this once near the
// top of the buyer shell.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/notification_provider.dart';

class WishlistMatchBanner extends ConsumerWidget {
  const WishlistMatchBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The snackbar uses the theme's secondary (Elegant Green on light,
    // Teal Green on dark) as the success background. The foreground
    // is `onSecondary` so contrast stays correct on either theme.

    // Watching the stream causes the widget to rebuild on every event;
    // the post-frame callback surfaces the banner once per change.
    ref.listen<AsyncValue<WishlistMatch?>>(
      wishlistMatchEventsProvider,
      (_, next) {
        final match = next.valueOrNull;
        if (match == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final cs = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🐟 ${match.item.displayName} sasa inapatikana karibu nawe!',
                style: TextStyle(color: cs.onSecondary),
              ),
              backgroundColor: cs.secondary,
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