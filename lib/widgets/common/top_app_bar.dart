// Premium global Top App Bar.
//
// Layout (left → right):
//   • Profile avatar button (far left) → navigates to /settings
//   • [flex spacer]
//   • Notifications bell with unread badge (role-aware route)
//   • Theme toggle (dark_mode ⇄ light_mode)
//
// All three actions live in a single `Row` with the standard 48x48
// touch targets so the AppBar is symmetrical, minimal and premium
// across every dashboard (buyer, street seller, admin).
//
// The widget is intentionally a `StatelessWidget` for the static
// layout — but its child action buttons remain stateful / reactive
// (notifications badge streams unread count, theme toggle reads the
// active mode and flips it live).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';

/// Global Top App Bar used by every dashboard screen.
///
/// Designed to slot straight into a `Scaffold.appBar` slot — render
/// it via `TopAppBar()` and Flutter handles the Material chrome
/// (status-bar / safe-area / elevation) around it.
///
/// The bell routes notifications to a role-aware path so the same
/// widget works for buyer, street seller and admin without callers
/// having to opt in.
class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  /// Standard AppBar height so we still satisfy `PreferredSizeWidget`.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Notifications route is role-aware:
  ///   • buyer         → /buyer/notifications (existing screen)
  ///   • streetSeller  → /seller/notifications
  ///   • admin         → /admin/notifications
  /// Callers can override via [notificationsPath] for screens that
  /// host their own notifications UI (e.g. detail screens).
  static String notificationsPathFor(UserRole? role) {
    switch (role) {
      case UserRole.buyer:
        return '/buyer/notifications';
      case UserRole.streetSeller:
        return '/seller/notifications';
      case UserRole.admin:
        return '/admin/notifications';
      case null:
        return '/buyer/notifications';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    // Stream the signed-in user so the avatar initials / network
    // image update as soon as the profile is loaded.
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    final role = user?.role;

    // Use the session-agnostic provider so the bell surfaces
    // notifications for sellers (and any non-buyer role) too —
    // `unreadNotificationsCountProvider` is gated on
    // `currentBuyerSessionProvider` and would otherwise return 0
    // for the seller dashboard.
    final unreadAsync = ref.watch(
      unreadCountForAnyUserProvider(user?.userId ?? ''),
    );
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor ?? cs.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM),
            child: Row(
              children: [
                // ── Profile avatar (far left) ────────────────────────────────
                _ProfileAvatar(
                  displayName: user?.fullName ?? '',
                  photoUrl: user?.profilePictureUrl,
                  onTap: () => context.push('/settings'),
                ),
                const Spacer(),
                // ── Notifications bell ────────────────────────────────────────
                _IconAction(
                  tooltip: l10n.notifications,
                  onTap: () => context.push(notificationsPathFor(role)),
                  badgeCount: unreadCount,
                  child: const Icon(
                    Icons.notifications_outlined,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingXS),
                // ── Theme toggle ──────────────────────────────────────────────
                _IconAction(
                  tooltip:
                      isDark ? l10n.switchToLightTheme : l10n.switchToDarkTheme,
                  badgeCount: 0,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setMode(isDark ? AppThemeMode.light : AppThemeMode.dark),
                  // Wrap the icon in an AnimatedSwitcher so it
                  // cross-fades + rotates when the theme flips.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) {
                      return RotationTransition(
                        turns:
                            Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      key: ValueKey<bool>(isDark),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 48x48 touch target around a circular avatar. Falls back to the
/// user's initials (or a generic person icon) when no photo is set.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.photoUrl,
    required this.onTap,
  });

  final String displayName;
  final String? photoUrl;
  final VoidCallback onTap;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _initials(displayName);
    final showPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      // 48x48 minimum touch target per Material Design 3 guidance.
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: showPhoto
                ? ClipOval(
                    child: Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) => _AvatarFallback(
                        initials: initials,
                        cs: cs,
                      ),
                    ),
                  )
                : _AvatarFallback(initials: initials, cs: cs),
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials, required this.cs});

  final String initials;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (initials.isEmpty) {
      return Icon(
        Icons.person_rounded,
        size: 20,
        color: cs.primary,
      );
    }
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// 48x48 touch target wrapping a single icon button.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.tooltip,
    required this.onTap,
    required this.child,
    required this.badgeCount,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;

    final button = SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: fg, size: 26),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (badgeCount <= 0) return button;

    // Badge overlay — small red dot with the unread count.
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          button,
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Theme.of(context).appBarTheme.backgroundColor ??
                      Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
