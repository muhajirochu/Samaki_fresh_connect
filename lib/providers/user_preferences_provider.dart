// User preferences — per-user notification, privacy, and
// onboarding toggles stored in SharedPreferences.
//
// IMPORTANT: like theme, these preferences are PERSONAL — they are
// keyed by the signed-in user's uid, never shared across accounts
// on the same device. The admin has no surface to change another
// user's preferences; these toggles are exposed only on the
// Settings screen that every user (buyer, seller, admin) reaches
// from their TopAppBar profile avatar.

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/storage_service.dart';
import 'auth_provider.dart';

/// Shape of the personal preference set. Booleans default to
/// `true` so a freshly-installed app respects the same defaults the
/// platform team agreed on (push notifications on, location
/// sharing on, etc.).
class UserPreferences {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool orderUpdates;
  final bool promotions;
  final bool showOnlineStatus;
  final bool shareLocation;

  const UserPreferences({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.orderUpdates = true,
    this.promotions = false,
    this.showOnlineStatus = true,
    this.shareLocation = true,
  });

  UserPreferences copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? orderUpdates,
    bool? promotions,
    bool? showOnlineStatus,
    bool? shareLocation,
  }) {
    return UserPreferences(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      shareLocation: shareLocation ?? this.shareLocation,
    );
  }
}

/// Internal store: a per-user slot in SharedPreferences that maps
/// each preference to its stored string ("true"/"false").
class UserPreferencesStore {
  static const String _prefix = 'app.userPrefs.v1';
  static const String _keyAnonymous = '$_prefix.guest';

  static String _keyFor(String uid) =>
      uid.isEmpty ? _keyAnonymous : '$_prefix.user.$uid';

  /// Read the preferences for [uid]. Missing keys fall back to the
  /// [UserPreferences] defaults so an upgrade from a build that
  /// never wrote prefs doesn't accidentally disable notifications.
  UserPreferences read(String uid) {
    if (kIsWeb) return const UserPreferences();
    final key = _keyFor(uid);
    bool readBool(String name, bool fallback) {
      try {
        final raw = StorageService.instance.getString('$key.$name');
        if (raw == null) return fallback;
        return raw == 'true';
      } on Object catch (_) {
        return fallback;
      }
    }

    return UserPreferences(
      pushNotifications: readBool('push', true),
      emailNotifications: readBool('email', true),
      orderUpdates: readBool('orderUpdates', true),
      promotions: readBool('promotions', false),
      showOnlineStatus: readBool('showOnlineStatus', true),
      shareLocation: readBool('shareLocation', true),
    );
  }

  /// Persist a single preference. The store does NOT hold state —
  /// the controller owns the in-memory copy and we write through
  /// here so each toggle hits SharedPreferences exactly once.
  Future<void> write(
    String uid, {
    bool? pushNotifications,
    bool? emailNotifications,
    bool? orderUpdates,
    bool? promotions,
    bool? showOnlineStatus,
    bool? shareLocation,
  }) async {
    if (kIsWeb) return;
    final key = _keyFor(uid);
    Future<void> put(String name, bool? value) async {
      if (value == null) return;
      try {
        await StorageService.instance.setString(
          '$key.$name',
          value ? 'true' : 'false',
        );
      } on Object catch (e) {
        debugPrint('Failed to persist user preference $name: $e');
      }
    }

    await put('push', pushNotifications);
    await put('email', emailNotifications);
    await put('orderUpdates', orderUpdates);
    await put('promotions', promotions);
    await put('showOnlineStatus', showOnlineStatus);
    await put('shareLocation', shareLocation);
  }
}

/// Riverpod-managed state holder for the active user's preferences.
/// Subscribes to the signed-in user (including demo mockUser) so a
/// sign-in / sign-out swap reloads the correct per-user slot.
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier(this._uid) : super(const UserPreferences()) {
    _reload();
  }

  String _uid;
  final UserPreferencesStore _store = UserPreferencesStore();

  String get uid => _uid;

  /// Swap the in-memory state to the preferences stored for [uid].
  /// Called when the signed-in account changes.
  void loadForUser(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _reload();
  }

  void _reload() {
    state = _store.read(_uid);
  }

  Future<void> setPushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    await _store.write(_uid, pushNotifications: value);
  }

  Future<void> setEmailNotifications(bool value) async {
    state = state.copyWith(emailNotifications: value);
    await _store.write(_uid, emailNotifications: value);
  }

  Future<void> setOrderUpdates(bool value) async {
    state = state.copyWith(orderUpdates: value);
    await _store.write(_uid, orderUpdates: value);
  }

  Future<void> setPromotions(bool value) async {
    state = state.copyWith(promotions: value);
    await _store.write(_uid, promotions: value);
  }

  Future<void> setShowOnlineStatus(bool value) async {
    state = state.copyWith(showOnlineStatus: value);
    await _store.write(_uid, showOnlineStatus: value);
  }

  Future<void> setShareLocation(bool value) async {
    state = state.copyWith(shareLocation: value);
    await _store.write(_uid, shareLocation: value);
  }
}

/// Singleton store so the controller can persist without
/// re-allocating on every toggle.
final userPreferencesStoreProvider = Provider<UserPreferencesStore>(
  (ref) => UserPreferencesStore(),
);

/// Active preferences for the signed-in user. Watches
/// `currentUserStreamProvider` so the in-memory state reloads
/// whenever the account changes.
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final authUid = ref.watch(currentUserStreamProvider).valueOrNull?.userId;
  final demoUid = mockUser?.userId;
  final uid = authUid ?? demoUid ?? '';
  final notifier = UserPreferencesNotifier(uid);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Convenience selector for settings screens.
final pushNotificationsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(
    userPreferencesProvider.select((p) => p.pushNotifications),
  ),
);

final emailNotificationsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(
    userPreferencesProvider.select((p) => p.emailNotifications),
  ),
);

final orderUpdatesEnabledProvider = Provider<bool>(
  (ref) => ref.watch(
    userPreferencesProvider.select((p) => p.orderUpdates),
  ),
);

final promotionsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(
    userPreferencesProvider.select((p) => p.promotions),
  ),
);

final showOnlineStatusEnabledProvider = Provider<bool>(
  (ref) => ref.watch(
    userPreferencesProvider.select((p) => p.showOnlineStatus),
  ),
);

final shareLocationEnabledProvider = Provider<bool>(
  (ref) => ref.watch(
    userPreferencesProvider.select((p) => p.shareLocation),
  ),
);