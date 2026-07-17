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
//   3. Notifications — push / email / order-updates / promotions
//      toggles. Per-user via [UserPreferencesNotifier].
//   4. Privacy — show online status, share location toggles.
//      Per-user.
//   5. About — version, open-source licenses, privacy policy,
//      terms of service. Read-only links.
//   6. Account — Edit Profile shortcut + Sign Out (with
//      confirmation dialog).
//
// ADMIN NOTE: this screen is identical for buyer, street seller and
// admin. There is no admin-only tile or admin-only theme control
// here. The only path that mutates a theme is the per-user
// Settings screen itself; the admin has no "Manage Themes" or
// equivalent capability. Theme + preferences are personal settings
// for the signed-in user.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_preferences_provider.dart';
import 'language_selector_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeControllerProvider.notifier);
    final activeLocale = ref.watch(localeProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bg = BackgroundStyle.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Appearance section ────────────────────────────────────────
              _SectionHeader(
                title: l10n.appearance,
                subtitle: l10n.themePreference,
              ),
              const SizedBox(height: 16),
              for (final candidate in AppThemeMode.values) ...[
                _ThemePreviewCard(
                  mode: candidate,
                  selected: candidate == mode,
                  onTap: () => notifier.setMode(candidate),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bg.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bg.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        size: 22,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.live,
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            l10n.appearanceLiveHint,
                            style: tt.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingXL),

              // ── Language section ────────────────────────────────────────
              _SectionHeader(
                title: l10n.language,
                subtitle: l10n.languagePreference,
              ),
              const SizedBox(height: 16),
              _LanguagePickerTile(
                activeLocale: activeLocale,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LanguageSelectorScreen(),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.paddingXL),

              // ── Notifications section ──────────────────────────────────
              _SectionHeader(
                title: l10n.notificationsSection,
                subtitle: l10n.notificationsSubtitle,
                leadingIcon: Icons.notifications_rounded,
              ),
              const SizedBox(height: 16),
              const _NotificationsCard(),

              const SizedBox(height: AppSizes.paddingXL),

              // ── Privacy section ────────────────────────────────────────
              _SectionHeader(
                title: l10n.privacySection,
                subtitle: l10n.privacySubtitle,
                leadingIcon: Icons.shield_rounded,
              ),
              const SizedBox(height: 16),
              const _PrivacyCard(),

              const SizedBox(height: AppSizes.paddingXL),

              // ── About section ──────────────────────────────────────────
              _SectionHeader(
                title: l10n.aboutSection,
                subtitle: l10n.aboutSubtitle,
                leadingIcon: Icons.info_rounded,
              ),
              const SizedBox(height: 16),
              const _AboutCard(),

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
// Adds an optional `leadingIcon` so Appearance / Notifications /
// Privacy / About / Account all share the same compact visual
// identity. Appearance used to omit the icon (it had its own
// palette mini-card); the rest now follow the same pattern.

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

// ── Theme preview card (unchanged) ───────────────────────────────────────

class _ThemePreviewCard extends StatelessWidget {
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColorTokens.of(mode);
    final currentCs = Theme.of(context).colorScheme;
    final currentTt = Theme.of(context).textTheme;
    final borderColor =
        selected ? currentCs.primary : Theme.of(context).dividerColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 0.6,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: currentCs.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MockMiniSurface(tokens: tokens),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mode.label,
                      style: currentTt.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.subtitle,
                      style: currentTt.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    _MockButton(tokens: tokens),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SelectionIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockMiniSurface extends StatelessWidget {
  final AppColorTokens tokens;
  const _MockMiniSurface({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 130,
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 18,
              color: tokens.background,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 28,
                height: 6,
                decoration: BoxDecoration(
                  color: tokens.textPrimary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Container(height: 2, color: tokens.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      width: 60,
                      decoration: BoxDecoration(
                        color: tokens.textPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 6,
                      width: 40,
                      decoration: BoxDecoration(
                        color: tokens.textHint,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: tokens.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tokens.border,
                          width: 0.6,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tokens.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: tokens.textHint,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockButton extends StatelessWidget {
  final AppColorTokens tokens;
  const _MockButton({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: tokens.background, size: 14),
          const SizedBox(width: 6),
          Text(
            tokens.brightness == Brightness.dark ? 'Deep Navy' : 'Modern Blue',
            style: TextStyle(
              color: tokens.background,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool selected;
  const _SelectionIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cs.primary : Theme.of(context).dividerColor,
          width: 1.4,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 16, color: cs.onPrimary)
          : null,
    );
  }
}

// ── Language picker tile (unchanged) ─────────────────────────────────────

class _LanguagePickerTile extends StatelessWidget {
  const _LanguagePickerTile({
    required this.activeLocale,
    required this.onTap,
  });

  final Locale activeLocale;
  final VoidCallback onTap;

  String _displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (activeLocale.languageCode) {
      case 'sw':
        return l10n.kiswahili;
      case 'en':
      default:
        return l10n.english;
    }
  }

  String _flag(Locale locale) {
    switch (locale.languageCode) {
      case 'sw':
        return '🇹🇿';
      case 'en':
      default:
        return '🇬🇧';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
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
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLG),
                ),
                child:
                    Text(_flag(activeLocale), style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.language,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayName(context),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Notifications card ──────────────────────────────────────────────────
//
// Personal preference toggles, persisted per-user via
// [UserPreferencesNotifier]. Switches call set* methods on the
// notifier, which both update the in-memory state and write to
// the per-user SharedPreferences slot.

class _NotificationsCard extends ConsumerWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(userPreferencesProvider);
    final notifier = ref.read(userPreferencesProvider.notifier);
    return _PreferenceCard(
      children: [
        _ToggleRow(
          icon: Icons.notifications_active_rounded,
          title: l10n.notificationsPush,
          subtitle: l10n.notificationsPushSubtitle,
          value: prefs.pushNotifications,
          onChanged: notifier.setPushNotifications,
        ),
        _Divider(),
        _ToggleRow(
          icon: Icons.email_rounded,
          title: l10n.notificationsEmail,
          subtitle: l10n.notificationsEmailSubtitle,
          value: prefs.emailNotifications,
          onChanged: notifier.setEmailNotifications,
        ),
        _Divider(),
        _ToggleRow(
          icon: Icons.receipt_long_rounded,
          title: l10n.notificationsOrderUpdates,
          subtitle: l10n.notificationsOrderUpdatesSubtitle,
          value: prefs.orderUpdates,
          onChanged: notifier.setOrderUpdates,
        ),
        _Divider(),
        _ToggleRow(
          icon: Icons.campaign_rounded,
          title: l10n.notificationsPromotions,
          subtitle: l10n.notificationsPromotionsSubtitle,
          value: prefs.promotions,
          onChanged: notifier.setPromotions,
        ),
      ],
    );
  }
}

// ── Privacy card ────────────────────────────────────────────────────────

class _PrivacyCard extends ConsumerWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(userPreferencesProvider);
    final notifier = ref.read(userPreferencesProvider.notifier);
    return _PreferenceCard(
      children: [
        _ToggleRow(
          icon: Icons.visibility_rounded,
          title: l10n.privacyShowOnlineStatus,
          subtitle: l10n.privacyShowOnlineStatusSubtitle,
          value: prefs.showOnlineStatus,
          onChanged: notifier.setShowOnlineStatus,
        ),
        _Divider(),
        _ToggleRow(
          icon: Icons.location_on_rounded,
          title: l10n.privacyShowLocation,
          subtitle: l10n.privacyShowLocationSubtitle,
          value: prefs.shareLocation,
          onChanged: notifier.setShareLocation,
        ),
      ],
    );
  }
}

// ── About card ──────────────────────────────────────────────────────────
//
// Read-only links. Each opens a SnackBar marked "Coming soon" in
// the current build — the actual destinations (privacy policy,
// licenses, terms) are intentionally left to be wired to real
// URLs in a follow-up so this commit stays scoped to the
// settings-structure task.

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  void _comingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.comingSoon),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _PreferenceCard(
      children: [
        _LinkRow(
          icon: Icons.tag_rounded,
          title: l10n.aboutAppVersion,
          trailing: Text(
            'v1.0',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: null, // not interactive
        ),
        _Divider(),
        _LinkRow(
          icon: Icons.description_rounded,
          title: l10n.aboutViewLicenses,
          subtitle: l10n.aboutViewLicensesSubtitle,
          onTap: () => _comingSoon(context),
        ),
        _Divider(),
        _LinkRow(
          icon: Icons.privacy_tip_rounded,
          title: l10n.aboutPrivacyPolicy,
          subtitle: l10n.aboutPrivacyPolicySubtitle,
          onTap: () => _comingSoon(context),
        ),
        _Divider(),
        _LinkRow(
          icon: Icons.gavel_rounded,
          title: l10n.aboutTermsOfService,
          subtitle: l10n.aboutTermsOfServiceSubtitle,
          onTap: () => _comingSoon(context),
        ),
      ],
    );
  }
}

// ── Shared widgets for the three preference cards ──────────────────────

class _PreferenceCard extends StatelessWidget {
  final List<Widget> children;
  const _PreferenceCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 18,
      color: Theme.of(context).dividerColor,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) => onChanged(v),
            activeThumbColor: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _LinkRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
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
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Account actions card (unchanged) ────────────────────────────────────

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
    mockUser = null;
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    ref.invalidate(currentUserStreamProvider);
    ref.invalidate(currentUserDataProvider);
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) context.go('/login');
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