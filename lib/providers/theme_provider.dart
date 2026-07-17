// Theme controller + Riverpod providers for the two theme modes
// (light / dark).
//
// IMPORTANT — personal preference, not a global setting.
//
// Theme is stored per-user in SharedPreferences. Each signed-in
// account gets its own key derived from its uid (see
// [AppThemeMode.prefKeyFor]), so:
//   • buyer A on device X picks Dark → only buyer A sees Dark
//   • seller B on device X picks Light → only seller B sees Light
//   • admin C on device X picks Dark → only admin C sees Dark
//
// No user — not even the admin — has any "manage other users'
// themes" capability. There is no admin-level theme surface in the
// codebase; the Settings screen that every user reaches from the
// TopAppBar profile avatar is the only place a theme can be
// changed, and it only affects the currently signed-in user.
//
// Persists the user's choice via the existing `StorageService` so
// the selection survives app restarts and account switches. The
// whole UI re-themes live when the mode flips — no restart
// required.

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

/// Holds the active [AppThemeMode]. Riverpod-managed via
/// `themeControllerProvider`. Also keeps the simpler
/// `themeModeProvider` (a `StateProvider<AppThemeMode>`) in sync so
/// the root `MaterialApp` rebuilds the moment the mode flips.
class ThemeModeNotifier extends ChangeNotifier {
  AppThemeMode _mode;
  String _uid;
  // Optional Riverpod ref so [setMode] can notify the simpler
  // `themeModeProvider` (a `StateProvider`) directly. This avoids
  // the previous bug where `themeModeProvider` was a plain `Provider`
  // that never picked up the notifier's notifications reliably.
  void Function(AppThemeMode)? _bridge;

  ThemeModeNotifier(this._mode, this._uid);

  AppThemeMode get mode => _mode;

  /// Swap to a different mode and persist the choice **for the
  /// currently signed-in user**. Other users on the same device are
  /// unaffected because each account writes to its own
  /// `prefKeyFor(uid)` slot.
  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _bridge?.call(mode);
    final key = _uid.isEmpty
        ? AppThemeMode.prefKeyAnonymous
        : AppThemeMode.prefKeyFor(_uid);
    // Try to persist; failure here shouldn't crash the UI.
    try {
      await StorageService.instance.setString(key, mode.name);
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

  /// Switch the in-memory mode to the preference stored for [uid]
  /// without touching the on-disk value for the previous uid. Called
  /// when the signed-in user changes (sign in / sign out / role
  /// switch) so the theme swaps to the new user's saved choice
  /// instead of leaking the previous user's preference.
  Future<void> loadForUser(String uid) async {
    if (_uid == uid) return; // no-op if the user hasn't changed
    _uid = uid;
    final key = uid.isEmpty
        ? AppThemeMode.prefKeyAnonymous
        : AppThemeMode.prefKeyFor(uid);
    AppThemeMode next;
    try {
      final raw = StorageService.instance.getString(key);
      next = AppThemeMode.fromName(raw);
    } on Object catch (_) {
      next = AppThemeMode.light;
    }
    if (next == _mode) return;
    _mode = next;
    notifyListeners();
    _bridge?.call(next);
  }

  /// Wire a callback that re-emits the mode through a separate
  /// `StateProvider` so any consumer of `themeModeProvider` rebuilds.
  /// Called from the `themeControllerProvider` factory.
  void bindBridge(void Function(AppThemeMode) bridge) {
    _bridge = bridge;
  }
}

/// Resolves the initial mode from SharedPreferences (or the
/// [defaultMode] fallback). Tolerates legacy values from earlier
/// app versions via [AppThemeMode.fromName].
///
/// The lookup tries, in order:
///   1. the per-user slot for [uid] (the active user)
///   2. the anonymous slot (used before sign-in completes)
///   3. the legacy `app.themeMode.v2` key (one-shot migration for
///      users upgrading from previous versions)
///   4. [defaultMode]
Future<AppThemeMode> _resolveInitialMode(
  AppThemeMode defaultMode, {
  String uid = '',
}) async {
  try {
    final keys = <String>[
      if (uid.isNotEmpty) AppThemeMode.prefKeyFor(uid),
      AppThemeMode.prefKeyAnonymous,
      // Legacy single-slot key — read once so users upgrading from
      // pre-v3 builds keep their choice on the first launch.
      'app.themeMode.v2',
    ];
    for (final key in keys) {
      final raw = StorageService.instance.getString(key);
      if (raw != null) return AppThemeMode.fromName(raw);
    }
    return defaultMode;
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

/// One-shot migration: copy the legacy `app.themeMode.v2` value into
/// the anonymous slot so subsequent launches read the per-user /
/// per-anonymous key path. Runs once; if the legacy key is absent
/// or has already been migrated, this is a no-op.
Future<void> migrateLegacyThemeSlot() async {
  try {
    const legacy = 'app.themeMode.v2';
    final raw = StorageService.instance.getString(legacy);
    if (raw == null) return;
    await StorageService.instance.setString(
      AppThemeMode.prefKeyAnonymous,
      raw,
    );
    // Best-effort cleanup of the legacy slot so we don't keep
    // growing the prefs file. Ignore failures.
    try {
      await StorageService.instance.remove(legacy);
    } on Object catch (_) {/* ignore */}
  } on Object catch (_) {
    // Migration is best-effort; never block app startup on it.
  }
}

/// Riverpod-managed [ThemeModeNotifier]. Initialised with the cached
/// value from per-user storage on first read.
final themeControllerProvider = ChangeNotifierProvider<ThemeModeNotifier>(
  (ref) {
    final notifier = ThemeModeNotifier(_initialMode, '');
    // Wire the StateProvider bridge so every setMode / loadForUser
    // call also re-emits through `themeModeProvider`. Without this
    // bridge, `themeModeProvider` is a separate piece of state that
    // never sees the notifier's updates.
    notifier.bindBridge((mode) {
      ref.read(themeModeProvider.notifier).state = mode;
    });
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);

/// Convenience provider — exposes just the [AppThemeMode] value.
///
/// This is a `StateProvider` (not a plain `Provider`) so the value
/// it emits is its own first-class state. The old plain `Provider`
/// pattern relied on `themeControllerProvider` notifying, but in a
/// Riverpod graph where many consumers only `ref.watch` the mode
/// (not the notifier itself) the dependency wasn't always picked up.
/// Making this a `StateProvider` removes that fragility.
final themeModeProvider = StateProvider<AppThemeMode>(
  (_) => _initialMode,
);

/// Convenience provider — exposes the matching [AppColorTokens].
/// Widgets without a `BuildContext` (e.g. map painters, marker icon
/// builders) read this.
final themeTokensProvider = Provider<AppColorTokens>(
  (ref) => AppColorTokens.of(ref.watch(themeModeProvider)),
);

/// Per-user theme bootstrap. Subscribes to the current Firebase
/// user (or demo mock user) and re-loads the theme every time the
/// signed-in account changes — so signing in as a different user on
/// the same device immediately shows that user's theme instead of
/// inheriting the previous user's choice.
///
/// Returns the [ThemeModeNotifier] for advanced callers; most code
/// just uses [themeModeProvider] which already watches the notifier.
final userThemeBootstrapProvider = Provider<ThemeModeNotifier>((ref) {
  final notifier = ref.watch(themeControllerProvider.notifier);
  final userAsync = ref.watch(currentUserStreamProvider);
  // Read both the demo `mockUser` and the auth state so demo
  // accounts also trigger a re-load.
  final demoUid = mockUser?.userId;
  final authUid = userAsync.valueOrNull?.userId;
  final uid = authUid ?? demoUid ?? '';
  // Fire-and-forget — the notifier will notify on its own when the
  // disk read resolves.
  notifier.loadForUser(uid);
  return notifier;
});