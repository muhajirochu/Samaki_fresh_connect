// Language selector — premium two-tile picker identical in spirit to
// the Settings theme tiles. Tapping a tile flips the active locale
// live (no restart) and persists the choice via [LocaleNotifier].
//
// The picker only supports two languages right now; adding a third
// is a single entry in `kSupportedLocales` plus a translation file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme_extensions.dart';
import '../../constants/app_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class LanguageSelectorScreen extends ConsumerWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activeLocale = ref.watch(localeProvider);
    final notifier = ref.read(localeControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bg = BackgroundStyle.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.back,
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                title: l10n.chooseLanguage,
                subtitle: l10n.selectLanguageDescription,
              ),
              const SizedBox(height: 16),
              for (final candidate in kSupportedLocales) ...[
                _LanguageTile(
                  locale: candidate,
                  label: _labelFor(candidate, l10n),
                  flag: _flagFor(candidate),
                  selected: candidate.languageCode == activeLocale.languageCode,
                  onTap: () async {
                    await notifier.setLocale(candidate);
                    if (context.mounted) {
                      context.pop();
                    }
                  },
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
                        Icons.translate_rounded,
                        size: 22,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.languageSaved,
                            style: tt.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.selectLanguageDescription,
                            style: tt.bodySmall,
                          ),
                        ],
                      ),
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

  String _labelFor(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'sw':
        return l10n.kiswahili;
      case 'en':
      default:
        return l10n.english;
    }
  }

  String _flagFor(Locale locale) {
    switch (locale.languageCode) {
      case 'sw':
        return '🇹🇿';
      case 'en':
      default:
        return '🇬🇧';
    }
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.locale,
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final Locale locale;
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = selected ? cs.primary : Theme.of(context).dividerColor;

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
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 0.6,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.10)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                ),
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locale.languageCode.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
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
              ),
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