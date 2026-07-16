// Theme controller + Riverpod providers for the two theme modes
// (light / dark). Persists the user's choice in SharedPreferences via
// the existing `StorageService` so the selection survives app
// restarts. The whole UI re-themes live when the mode flips — no
// restart required.

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/app_colors.dart';
import '../services/storage_service.dart';

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
      await StorageService.instance.setString(AppThemeMode.prefKey, mode.name);
    } on Object catch (e) {
      debugPrint('Failed to persist theme mode: $e');
    }
  }

  /// Toggle helper — useful for an icon button on the AppBar.
  Future<void> toggle() async {
    await setMode(
      _mode == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light,
    );
  }
}

/// Resolves the initial mode from SharedPreferences (or the
/// [defaultMode] fallback). Tolerates legacy values from earlier app
/// versions (e.g. `cream`) via [AppThemeMode.fromName].
Future<AppThemeMode> _resolveInitialMode(AppThemeMode defaultMode) async {
  try {
    final raw = StorageService.instance.getString(AppThemeMode.prefKey);
    return AppThemeMode.fromName(raw);
  } on Object catch (_) {
    return defaultMode;
  }
}

/// Default theme — used when storage hasn't been read yet.
const AppThemeMode _defaultThemeMode = AppThemeMode.light;

/// Cached initial value, set once during bootstrap so the first
/// frame already renders in the right mode.
AppThemeMode _initialMode = _defaultThemeMode;

/// Called from `main.dart` after `StorageService.bootstrap()` resolves.
/// We can't use `Future` here because the ChangeNotifierProvider is
/// synchronous; the resolve happens once and the notifier is created
/// in the right state on the very first frame.
Future<void> bootstrapThemeNotifier() async {
  _initialMode = await _resolveInitialMode(_defaultThemeMode);
}

/// Riverpod-managed [ThemeModeNotifier]. Initialised with the cached
/// value from [AppThemeMode.prefKey] on first read.
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