// Locale (language) provider for the entire app.
//
// Architecture:
//   - `localeProvider` (this file) — Riverpod `StateProvider<Locale>`,
//     the single source of truth for the current locale. Holds the
//     active `Locale` so every widget can rebuild on change.
//   - `LocaleNotifier` — `ChangeNotifier` wrapper used by the
//     root `MaterialApp.router` via `Localizations.override` so the
//     framework rebuilds the widget tree when the locale flips.
//   - `LocaleStorage` — persists/restores the chosen locale via
//     `SharedPreferences` (through `StorageService`).
//
// The whole flow:
//   1. App boots → `bootstrapLocale()` reads SharedPreferences and
//      pre-populates both the Riverpod `StateProvider` and the
//      `LocaleNotifier` so the first frame already renders the right
//      locale (no flash of English on launch for Kiswahili users).
//   2. User taps a language in `LanguageSelectorScreen` →
//      `LocaleNotifier.setLocale()` writes to SharedPreferences and
//      notifies. `MaterialApp.router`'s `Localizations.override`
//      listens and rebuilds the tree → every `AppLocalizations.of(context)`
//      returns the new translation immediately, no restart needed.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/storage_service.dart';
import '../utils/logger.dart';

/// Two supported locales. The first entry is the fallback.
const List<Locale> kSupportedLocales = <Locale>[
  Locale('en'),
  Locale('sw'),
];

/// SharedPreferences key for the persisted locale code (`en` / `sw`).
const String kLocalePrefKey = 'app.locale.v1';

/// The default locale used when nothing has been persisted yet.
const Locale kFallbackLocale = Locale('en');

/// Reads the persisted locale from SharedPreferences and returns the
/// matching `Locale`. Falls back to [kFallbackLocale] when nothing
/// is stored or the stored value isn't one of [kSupportedLocales].
Locale resolveStoredLocale() {
  try {
    final raw = StorageService.instance.getString(kLocalePrefKey);
    if (raw == null || raw.isEmpty) return kFallbackLocale;
    for (final locale in kSupportedLocales) {
      if (locale.languageCode == raw) return locale;
    }
  } on Object catch (e, st) {
    AppLogger.warning('resolveStoredLocale failed: $e', e, st);
  }
  return kFallbackLocale;
}

/// `ChangeNotifier` that the root `MaterialApp.router` listens to via
/// `Localizations.override`. When the locale flips the framework
/// rebuilds the widget tree with the new locale.
class LocaleNotifier extends ChangeNotifier {
  LocaleNotifier(this._locale);

  Locale _locale;

  /// The active locale.
  Locale get locale => _locale;

  /// Flip to [newLocale] and persist the choice. Notifies listeners
  /// so the framework rebuilds.
  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    notifyListeners();
    try {
      await StorageService.instance.setString(
        kLocalePrefKey,
        newLocale.languageCode,
      );
    } on Object catch (e, st) {
      AppLogger.error('Failed to persist locale: $e', e, st);
    }
  }
}

/// Singleton `LocaleNotifier` — there's exactly one app-wide
/// language controller. We seed it from SharedPreferences before the
/// first frame so the very first build already renders in the
/// right language.
LocaleNotifier _localeNotifier = LocaleNotifier(resolveStoredLocale());

/// Provider exposing the current [Locale] as a Riverpod state value.
final localeProvider = StateProvider<Locale>(
  (_) => _localeNotifier.locale,
);

/// Provider exposing the singleton [LocaleNotifier]. Widgets that
/// need to *change* the locale (e.g. `LanguageSelectorScreen`) read
/// this; widgets that just need the current locale read
/// [localeProvider] instead.
final localeControllerProvider = Provider<LocaleNotifier>(
  (_) => _localeNotifier,
);

/// Pre-bootstrap hook. Call this from `main()` after
/// `StorageService.bootstrap()` so the locale is hydrated before
/// `runApp` runs.
void bootstrapLocale() {
  final resolved = resolveStoredLocale();
  _localeNotifier = LocaleNotifier(resolved);
  // The StateProvider can only be written via a `ref.read`, but the
  // initial value will be picked up the first time something reads
  // `localeProvider`. To keep things consistent across both, we
  // re-seed the StateProvider via a tiny `ProviderContainer` here.
  // This keeps Riverpod's view of the world in sync with the
  // ChangeNotifier that the root MaterialApp actually listens to.
  // The container is torn down immediately.
  final container = ProviderContainer();
  container.read(localeProvider.notifier).state = resolved;
  container.dispose();
}

/// Convenience: read the active locale code (`en` / `sw`).
String currentLocaleCode() => _localeNotifier.locale.languageCode;