// Empty-state widget shown when the buyer searches for a fish that no
// nearby seller stocks. The message text is the EXACT copy from the
// Phase 2 spec — do not paraphrase.
//
// Usage:
//   EmptyMapState(
//     onClear: () => ref.read(mapFilterControllerProvider.notifier).reset(),
//   )

import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';

class EmptyMapState extends StatelessWidget {
  /// Optional callback for a "clear filter" CTA. When null, the CTA
  /// is hidden.
  final VoidCallback? onClear;

  const EmptyMapState({super.key, this.onClear});

  static const String _message =
      'Samaki wa aina hii hawapatikani kwa sasa katika eneo lako. '
      'Tafadhali jaribu tena baadaye au tafuta aina nyingine ya samaki.';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXL,
          vertical: AppSizes.paddingLG,
        ),
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
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.set_meal_rounded,
                size: 56,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: AppSizes.paddingMD),
            Text(
              'Hakuna samaki walio patikana',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              _message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onClear != null) ...[
              const SizedBox(height: AppSizes.paddingLG),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Onyesha aina zote'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLG,
                    vertical: AppSizes.paddingSM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
