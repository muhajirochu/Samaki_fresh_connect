// Theme controller + Riverpod providers for the three theme modes
// (light / cream / dark). Persists the user's choice in
// SharedPreferences via the existing StorageService.

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/app_colors.dart';
import '../services/storage_service.dart';

/// The persisted storage key. Kept inside the [AppThemeMode] enum
/// for one source of truth.
const String kThemeModePrefKey = AppThemeMode.prefKey;

/// Holds the active [AppThemeMode]. We deliberately keep our own
/// [ChangeNotifier] rather than use Riverpod state directly so any
/// widget (including the platform one in `main.dart`) can subscribe.
class ThemeModeNotifier extends ChangeNotifier {
  AppThemeMode _mode;
  ThemeModeNotifier(this._mode);

  AppThemeMode get mode => _mode;

  /// Swap to a different mode and persist the choice.
  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    // Try to persist; failure here shouldn't crash the UI.
    try {
      await StorageService.instance.setString(kThemeModePrefKey, mode.name);
    } on Object catch (e) {
      debugPrint('Failed to persist theme mode: $e');
    }
  }
}

/// Resolves the initial mode from SharedPreferences (or the
/// [defaultMode] fallback).
Future<AppThemeMode> _resolveInitialMode(AppThemeMode defaultMode) async {
  try {
    final raw = StorageService.instance.getString(kThemeModePrefKey);
    if (raw != null) {
      for (final mode in AppThemeMode.values) {
        if (mode.name == raw) return mode;
      }
    }
  } on Object catch (_) {
    // Fall back to default if storage is unavailable.
  }
  return defaultMode;
}

/// Default theme — used when storage hasn't been read yet.
const AppThemeMode _defaultThemeMode = AppThemeMode.light;

/// Manual holder — set once the storage service has loaded.
AppThemeMode _initialMode = _defaultThemeMode;

/// Called from `main.dart` after `StorageService.init()` resolves.
/// We can't use `Future` here because the ChangeNotifierProvider is
/// synchronous; the resolve happens once and the notifier is created
/// in the right state on the very first frame.
Future<void> bootstrapThemeNotifier() async {
  _initialMode = await _resolveInitialMode(_defaultThemeMode);
}

/// Riverpod-managed [ThemeModeNotifier]. Initialised with the cached
/// value from [kThemeModePrefKey] on first read.
final themeControllerProvider = ChangeNotifierProvider<ThemeModeNotifier>(
  (ref) {
    final notifier = ThemeModeNotifier(_initialMode);
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);

/// Convenience provider — exposes just the [AppThemeMode] value.
final themeModeProvider = Provider<AppThemeMode>(
  (ref) => ref.watch(themeControllerProvider).mode,
);

/// Convenience provider — exposes the matching [AppColorTokens].
/// Widgets without a `BuildContext` (e.g. map painters, marker icon
/// builders) read this.
final themeTokensProvider = Provider<AppColorTokens>(
  (ref) => AppColorTokens.of(ref.watch(themeModeProvider)),
);
