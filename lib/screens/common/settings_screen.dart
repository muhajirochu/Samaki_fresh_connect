// Settings screen — premium single-column layout with three
// sections:
//
//   1. Appearance — theme picker (Light / Dark) with live preview
//      cards. Tapping a tile flips the global theme live (no
//      restart) and persists the choice to SharedPreferences via
//      [ThemeModeNotifier].
//
//   2. Language — language picker (English / Kiswahili). Tapping a
//      tile opens the dedicated selector screen; selection flips
//      the global locale live (no restart) and persists via
//      [LocaleNotifier].
//
//   3. Account — Edit Profile shortcut + Sign Out (with
//      confirmation dialog). Logout clears the auth session,
//      invalidates dependent providers, and routes the user back
//      to /login.
//
// The preview tiles in the Appearance section are mini mockups of
// the actual UI so the user can see exactly what they're picking
// before committing.

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
                subtitle:
                    'Choose how Samaki Fresh Connect looks across the whole app.',
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
                            'Your selection is applied instantly across every screen and saved for next time.',
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
                subtitle:
                    'Switch the entire app to your preferred language.',
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

              // ── Account section ─────────────────────────────────────────
              _SectionHeader(
                title: l10n.account,
                subtitle: l10n.logoutConfirmationMessage,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.headlineMedium?.copyWith(letterSpacing: -0.4),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: tt.bodyMedium),
      ],
    );
  }
}

/// Premium tappable tile that shows the currently-active language
/// and navigates to [LanguageSelectorScreen] when tapped. Symmetric
/// with the theme preview cards so the hub reads as one unit.
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

/// One tappable card per theme. Renders a mini "mock screen" using
/// the candidate's [AppColorTokens] so the user sees exactly what
/// they're picking — surface, card, accent stripe, sample text and
/// a primary button mock.
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

/// Tiny 88×120 mock of the theme's UI — background, app bar stripe,
/// card, accent dot. Renders inline using the candidate's tokens so
/// the preview is honest about what the user will see.
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
            // App-bar stripe
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
            // Accent line under app bar
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

/// Mock button rendered in the candidate's primary colour so the
/// preview also communicates "this is the colour buttons will use".
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

/// Account actions card surfaced from the Settings hub.
///
/// Two actions:
///   1. Edit Profile — navigates to /profile/edit so the user can
///      change name, phone, photo and street address.
///   2. Sign Out — clears the auth session, resets all dependent
///      providers, and routes the user back to /login.
///
/// Logout uses [authServiceProvider] + manual provider invalidation
/// (the same pattern used in ProfileScreen) so demo users and real
/// Firebase users both end up signed out cleanly.
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
          // ── Edit profile row ─────────────────────────────────────────
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
          // Divider between Edit Profile and Sign Out rows
          Divider(
            height: 1,
            indent: 76,
            endIndent: 18,
            color: Theme.of(context).dividerColor,
          ),
          // ── Sign out row ─────────────────────────────────────────────
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