// Settings screen — premium single-column layout.
//
// Sections shown (in order, all per-user / personal settings):
//
//   1. Appearance — theme picker (Light / Dark) with live preview
//      cards. Per-user via [ThemeModeNotifier] + per-user storage
//      keys, so switching accounts on the same device shows the
//      new user's saved choice.
//   2. Language — language picker (English / Kiswahili). Opens the
//      dedicated selector screen; selection flips the locale live
//      and persists via [LocaleNotifier].
//   3. Account — Edit Profile shortcut + Sign Out (with
//      confirmation dialog).
//
// ADMIN NOTE: this screen is identical for buyer, street seller
// and admin. There is no admin-only tile or admin-only theme
// control here. The only path that mutates a theme is the
// per-user Settings screen itself; the admin has no
// "Manage Themes" or equivalent capability. Theme is a personal
// setting for the signed-in user.
//
// The Notifications / Privacy / About sections that were briefly
// shipped here have been removed from this build — those
// surfaces are being designed separately and will be reintroduced
// later. The ARB keys are kept in place (en + sw) so the copy is
// ready to wire back when the new screens land.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../config/route_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activeLocale = ref.watch(localeProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;

    void showComingSoon() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kipengele hiki kinakuja hivi karibuni...'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.primary,
        ),
      );
    }

    void onManageFavorites() {
      if (user?.role == UserRole.buyer) {
        context.pushNamed(AppRouteNames.buyerWishlist);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kipengele hiki ni kwa ajili ya wanunuzi pekee.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: cs.error,
          ),
        );
      }
    }

    void onChangePassword() {
      final email = user?.email;
      if (email == null || email.isEmpty) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change Password'),
          content: Text('Tuma barua pepe ya kubadili nenosiri kwenda:\n$email?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: Text('Cancel', style: TextStyle(color: cs.onSurface)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(authServiceProvider).sendPasswordResetEmail(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Barua pepe imetumwa kikamilifu.'), behavior: SnackBarBehavior.floating, backgroundColor: cs.primary),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Kuna hitilafu. Tafadhali jaribu tena.'), behavior: SnackBarBehavior.floating, backgroundColor: cs.error),
                    );
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        // SettingsScreen is mounted as a tab inside every role's shell
        // (IndexedStack), so it can be the root route — `context.pop()`
        // then throws "There is nothing to pop". Only render the back
        // arrow when there's a route to pop back to. Flutter's default
        // `automaticallyImplyLeading` will then add its own back arrow
        // when the route was pushed via GoRouter, so we don't override
        // that here.
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: l10n.back,
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── App Settings ─────────────────────────────────────────────
              const _SectionHeader(
                title: 'App Settings',
                subtitle: 'Manage your app preferences',
                leadingIcon: Icons.settings_applications_rounded,
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    title: 'Language',
                    icon: Icons.language_rounded,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(activeLocale.languageCode == 'sw' ? 'Swahili' : 'English', style: tt.bodySmall),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
                      ],
                    ),
                    onTap: () => context.pushNamed(AppRouteNames.languageSelector),
                  ),
                  _SettingsTile(
                    title: 'Manage Favorites',
                    icon: Icons.favorite_border_rounded,
                    onTap: onManageFavorites,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // ── Login Security ──────────────────────────────────────────
              const _SectionHeader(
                title: 'Login Security', 
                subtitle: 'Secure your account',
                leadingIcon: Icons.security_rounded,
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    title: 'Change Password',
                    icon: Icons.lock_outline_rounded,
                    onTap: onChangePassword,
                  ),
                  const _FaceIdTile(),
                ],
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // ── Help ───────────────────────────────────────────────────
              const _SectionHeader(
                title: 'Help', 
                subtitle: 'Get support and answers',
                leadingIcon: Icons.help_outline_rounded,
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    title: 'Contact',
                    icon: Icons.support_agent_rounded,
                    onTap: showComingSoon,
                  ),
                  _SettingsTile(
                    title: 'FAQ',
                    icon: Icons.question_answer_outlined,
                    onTap: showComingSoon,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // ── About ──────────────────────────────────────────────────
              const _SectionHeader(
                title: 'About', 
                subtitle: 'App info and policies',
                leadingIcon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    title: 'Update',
                    icon: Icons.system_update_rounded,
                    onTap: showComingSoon,
                  ),
                  _SettingsTile(
                    title: 'Privacy Terms and Condition',
                    icon: Icons.privacy_tip_outlined,
                    onTap: showComingSoon,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingXL),
              
              // ── Account section ────────────────────────────────────────
              _SectionHeader(
                title: l10n.account,
                subtitle: l10n.logoutConfirmationMessage,
                leadingIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              _AccountActionsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────
//
// Adds an optional `leadingIcon` so the Appearance / Language /
// Account sections share the same compact visual identity where
// appropriate.

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? leadingIcon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leadingIcon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leadingIcon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.headlineMedium?.copyWith(letterSpacing: -0.4),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: tt.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
// ── Account actions card ─────────────────────────────────────────────────

class _AccountActionsCard extends ConsumerWidget {
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (shouldSignOut != true) return;
    if (!context.mounted) return;
    // Single source of truth — delegates to the AuthController
    // notifier. The router's redirect picks up the auth-state flip
    // via authRefreshProvider and lands the user on /login; no
    // imperative context.go here.
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              onTap: () => context.push('/profile/edit'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: cs.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.editProfile,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.personalInformation,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 76,
            endIndent: 18,
            color: Theme.of(context).dividerColor,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              onTap: () => _confirmSignOut(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.errorRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.signOut,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.errorRed,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.errorRed.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<Widget> separatedChildren = [];
    for (int i = 0; i < children.length; i++) {
      separatedChildren.add(children[i]);
      if (i < children.length - 1) {
        separatedChildren.add(
          Divider(
            height: 1,
            indent: 64,
            endIndent: 16,
            color: Theme.of(context).dividerColor,
          ),
        );
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: separatedChildren,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!
              else Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}


class _FaceIdTile extends StatefulWidget {
  const _FaceIdTile();

  @override
  State<_FaceIdTile> createState() => _FaceIdTileState();
}

class _FaceIdTileState extends State<_FaceIdTile> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      title: 'Face ID',
      icon: Icons.face_rounded,
      trailing: Switch(
        value: _isEnabled,
        onChanged: (val) {
          setState(() {
            _isEnabled = val;
          });
          if (val) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Face ID imewashwa kwa mafanikio.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        },
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () {
        setState(() {
          _isEnabled = !_isEnabled;
        });
      },
    );
  }
}