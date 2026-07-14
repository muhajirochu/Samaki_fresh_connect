// Reusable [AppBar] action cluster used on every screen that needs
// the global theme switcher + notifications bell + (optional) wishlist
// shortcut.
//
// Pass `showTheme: false` to omit the theme button (e.g. on screens
// that already render their own theme toggle inside the body). The
// order — theme, notifications, wishlist — keeps the icons grouped
// consistently across the app so users always find the theme switcher
// in the same spot.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../notifications/notifications_bell.dart';
import '../settings/theme_switcher_icon_button.dart';

class AppBarActionsBar extends StatelessWidget {
  /// Whether to render the wishlist shortcut. Defaults to `true` —
  /// pass `false` for screens like the wishlist page itself where a
  /// "go to wishlist" button would be redundant.
  final bool showWishlist;

  /// Whether to render the notifications bell. Defaults to `true`.
  final bool showNotifications;

  /// Whether to render the theme switcher button. Defaults to `true`.
  final bool showTheme;

  /// Wishlist tooltip text shown in the accessibility / semantic
  /// tree.
  final String wishlistTooltip;

  const AppBarActionsBar({
    super.key,
    this.showWishlist = true,
    this.showNotifications = true,
    this.showTheme = true,
    this.wishlistTooltip = 'Wishlist',
  });

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;
    final children = <Widget>[];
    if (showTheme) {
      children.add(const ThemeSwitcherIconButton());
    }
    if (showNotifications) {
      children.add(const NotificationsBell());
    }
    if (showWishlist) {
      children.add(
        IconButton(
          tooltip: wishlistTooltip,
          icon: const Icon(Icons.favorite_border_rounded),
          color: fg,
          onPressed: () => context.push('/buyer/wishlist'),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
