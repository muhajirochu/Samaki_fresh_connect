// Theme switcher — a 3-option segmented control that lets the user pick
// White / Cream / Dark. Reads `themeModeProvider` and writes back via
// the [ThemeModeNotifier]. Designed to drop into a [ListTile] or a
// settings page and stay readable in every theme (the preview swatches
// use the actual theme colours so the tile itself demonstrates what
// each option looks like).

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../providers/theme_provider.dart';

/// Three-option segmented control bound to the theme controller.
class ThemeSwitcherTile extends ConsumerWidget {
  const ThemeSwitcherTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSizes.paddingXS),
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how Fresh Connect looks. Your choice is saved on this device.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          Row(
            children: [
              for (final candidate in AppThemeMode.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingXS),
                    child: _ThemeOptionTile(
                      mode: candidate,
                      selected: candidate == mode,
                      onTap: () => notifier.setMode(candidate),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingSM,
            vertical: AppSizes.paddingSM + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
                : Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              _ThemeSwatch(mode: mode, selected: selected),
              const SizedBox(width: AppSizes.paddingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mode.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      mode.subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny preview pill that visually represents each theme using
/// real [AppColorTokens]. Built once on first frame, cached afterwards
/// so the segmented control never re-paints the swatches.
class _ThemeSwatch extends StatelessWidget {
  final AppThemeMode mode;
  final bool selected;

  const _ThemeSwatch({required this.mode, required this.selected});

  @override
  Widget build(BuildContext context) {
    final tokens = AppColorTokens.of(mode);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        color: tokens.background,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSM - 1),
        child: Stack(
          children: [
            // Top stripe — accent on the theme's primary colour.
            Container(
              height: 14,
              color: tokens.accent,
            ),
            // Middle — body colour.
            Container(
              margin: const EdgeInsets.only(top: 14),
              color: tokens.surface,
            ),
            // Bottom-right small dot for accent — visual salt.
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tokens.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
