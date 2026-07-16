// Compact theme switcher intended for [AppBar] action slots. Shows
// a single icon button that opens a popup menu with the two theme
// options — Light / Dark — each rendered with a coloured swatch and
// label. Tapping an option updates the global theme via the
// [ThemeModeNotifier] and the entire app rebuilds under the new
// colorscheme. Also offers a one-tap jump to the full Settings screen
// for a richer preview.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../providers/theme_provider.dart';

/// Discriminated value for the popup menu: when [mode] is non-null it
/// triggers a theme switch; when it's null the "All settings" row was
/// tapped and we navigate to the Settings screen.
class _PopupValue {
  final AppThemeMode? mode;
  const _PopupValue(this.mode);
}

/// AppBar-friendly action that exposes the two theme choices as a
/// popup menu. Designed to live next to the notifications bell.
class ThemeSwitcherIconButton extends ConsumerWidget {
  const ThemeSwitcherIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return PopupMenuButton<_PopupValue>(
      tooltip: 'Switch theme',
      icon: Icon(
        _modeIcon(mode),
        color: Theme.of(context).appBarTheme.foregroundColor ??
            Theme.of(context).colorScheme.onSurface,
      ),
      color: Theme.of(context).colorScheme.surface,
      onSelected: (selected) {
        if (selected.mode != null) {
          ref.read(themeControllerProvider.notifier).setMode(selected.mode!);
        } else {
          context.push('/settings');
        }
      },
      itemBuilder: (ctx) => [
        for (final candidate in AppThemeMode.values)
          PopupMenuItem<_PopupValue>(
            value: _PopupValue(candidate),
            child: _ThemeMenuRow(
              mode: candidate,
              selected: candidate == mode,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<_PopupValue>(
          value: const _PopupValue(null),
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'All settings',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _modeIcon(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.light => Icons.light_mode_rounded,
      AppThemeMode.dark => Icons.dark_mode_rounded,
    };
  }
}

/// Row that lives inside the popup menu — coloured swatch + label +
/// check-mark when the option is active.
class _ThemeMenuRow extends StatelessWidget {
  final AppThemeMode mode;
  final bool selected;

  const _ThemeMenuRow({required this.mode, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThemeSwatch(mode: mode),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mode.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              mode.subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        if (selected) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.check_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
        ],
      ],
    );
  }
}

/// Compact 24×18 swatch — looks like a tiny version of the theme's
/// surface with an accent stripe. Used in popup menu rows.
class _ThemeSwatch extends StatelessWidget {
  final AppThemeMode mode;
  const _ThemeSwatch({required this.mode});

  @override
  Widget build(BuildContext context) {
    final tokens = AppColorTokens.of(mode);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: tokens.background,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Container(
              height: 10,
              color: tokens.accent,
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 6,
                height: 6,
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
