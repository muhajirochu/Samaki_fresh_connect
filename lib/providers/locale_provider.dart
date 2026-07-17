// Locale (language) provider for the entire app.
//
// Architecture:
//   - `localeProvider` — Riverpod `NotifierProvider<LocaleNotifier, Locale>`
//     the single source of truth for the current locale.
//   - `LocaleNotifier` — the notifier holding the active `Locale`.
//     Mutating its `state` rebuilds every widget that watches
//     [localeProvider] AND notifies the legacy ChangeNotifier
//     bridge so the root `MaterialApp.router` (which listens via
//     `Localizations.override`) re-translates the tree instantly.
//   - SharedPreferences via `StorageService` persists the choice so
//     it survives app restarts.
//
// The whole flow:
//   1. App boots → `bootstrapLocale()` reads SharedPreferences and
//      seeds the singleton used by `Localizations.override` so the
//      very first frame already renders the right language.
//   2. User taps a language in `LanguageSelectorScreen` →
//      `LocaleNotifier.setLocale()` updates `state` AND notifies
//      the legacy bridge. `MaterialApp.router`'s `builder` rebuilds
//      with `Localizations.override(locale: notifier.locale)`, so
//      every `AppLocalizations.of(context)` returns the new
//      translation immediately, no restart needed.

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

/// Legacy `ChangeNotifier` that the root `MaterialApp.router` listens
/// to via `Localizations.override`. The Riverpod [LocaleNotifier]
/// below keeps this in sync so both reactive systems see every
/// change.
class LocaleChangeBridge extends ChangeNotifier {
  Locale _locale = resolveStoredLocale();

  /// The active locale.
  Locale get locale => _locale;

  /// Update the bridge's locale AND notify listeners so the root
  /// MaterialApp rebuilds with the new locale.
  set locale(Locale value) {
    if (_locale.languageCode == value.languageCode) return;
    _locale = value;
    notifyListeners();
  }
}

/// Singleton bridge — there's exactly one app-wide language
/// listener for the legacy `Localizations.override` API.
final LocaleChangeBridge _bridge = LocaleChangeBridge();

/// Riverpod `Notifier<Locale>` — every widget that `ref.watch`es
/// [localeProvider] rebuilds the moment [setLocale] is called.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => _bridge.locale;

  /// The active locale. Alias for `state`.
  Locale get locale => state;

  /// Flip to [newLocale] and persist the choice.
  Future<void> setLocale(Locale newLocale) async {
    if (state.languageCode == newLocale.languageCode) return;
    state = newLocale;
    // Keep the legacy ChangeNotifier bridge in sync so the root
    // MaterialApp's `Localizations.override` rebuilds the tree.
    _bridge.locale = newLocale;
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

/// Riverpod-managed [Locale] — every widget that `ref.watch`es this
/// rebuilds the moment the user picks a new language.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Provider exposing the same [LocaleNotifier] singleton used by
/// [localeProvider]. Use this when you need to *change* the locale
/// (e.g. `LanguageSelectorScreen`); use [localeProvider] when you
/// just need to read the current locale.
final localeControllerProvider = Provider<LocaleNotifier>(
  (ref) => ref.watch(localeProvider.notifier),
);

/// Pre-bootstrap hook. Call this from `main()` after
/// `StorageService.bootstrap()` so the locale is hydrated before
/// `runApp` runs.
void bootstrapLocale() {
  final resolved = resolveStoredLocale();
  _bridge.locale = resolved;
}