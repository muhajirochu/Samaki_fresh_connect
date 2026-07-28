import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

// ── Service Providers ─────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final userServiceProvider = Provider<UserService>((ref) => UserService());

// Global offline mock user variable (shared across all ProviderContainers and GoRouter)
// Set it via [setMockUser] (the public setter below) so every downstream
// provider rebuilds. Writing to it directly will silently leave the
// reactive counter stuck.
UserModel? mockUser;

// ── Reactive mock-user counter ───────────────────────────────────────────────
//
// Whenever [mockUser] is reassigned (sign in / sign out / role swap)
// the counter ticks so any provider that reads it rebuilds. This is the
// single point of reactivity for the offline / demo path — the real
// Firebase-auth path tracks via [authStateProvider].
//
// Internal — exposed (without the leading underscore) for tests via
// `mockUserTickSeed`.
int mockUserTickSeed = 0;

void _bumpMockUser() => mockUserTickSeed++;

/// Public entry-point so callers can `import '...auth_provider.dart';
/// setMockUser(...);` without colliding with the top-level
/// `mockUser` field. Updates the global mock user AND bumps the
/// reactive counter so every downstream provider rebuilds.
void setMockUser(UserModel? value) {
  mockUser = value;
  _bumpMockUser();
  // Bump the active container's listener state so every consumer
  // of [mockUserTickProvider] rebuilds immediately.
  final container = _activeAuthContainer;
  if (container != null) {
    try {
      container.invalidate(mockUserTickListenerProvider);
    } on Object catch (_) {/* container may be disposed */}
  }
}

// Internal: when setMockUser() is called, we want to invalidate the
// listener state provider so every consumer of the corresponding
// provider rebuilds. Simplest way: keep a package-level reference to
// the active ProviderContainer (set via [bindAuthProviderContainer]).
ProviderContainer? _activeAuthContainer;

void bindAuthProviderContainer(ProviderContainer container) {
  _activeAuthContainer = container;
}

void unbindAuthProviderContainer(ProviderContainer container) {
  if (identical(_activeAuthContainer, container)) {
    _activeAuthContainer = null;
  }
}

// ── Firebase Auth Stream ───────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  // Touch the mock counter so we rebuild whenever mockUser changes.
  ref.watch(mockUserTickProvider);
  if (mockUser != null) {
    return Stream.value(MockFirebaseUser(mockUser!.userId, mockUser!.email));
  }
  final authService = ref.watch(authServiceProvider);
  return authService.authStateStream;
});

// ── Current Firebase User (reactive) ────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(mockUserTickProvider);
  if (mockUser != null) {
    return MockFirebaseUser(mockUser!.userId, mockUser!.email);
  }
  return ref.watch(authStateProvider).value;
});

// ── Current User Data — real-time stream (preferred over FutureProvider) ──────
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  // Watch the mock counter so the stream rebuilds when the demo
  // user switches, even though the underlying Firestore user doc is
  // the same.
  ref.watch(mockUserTickProvider);

  if (mockUser != null) {
    // Emit a `Stream.value` of the **current** mockUser. Because
    // `mockUserTickProvider` ticks on every setMockUser() call,
    // the whole stream is rebuilt and the brand-new
    // `Stream.value(mockUser)` captures the latest reference.
    return Stream.value(mockUser);
  }

  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);
  final userService = ref.watch(userServiceProvider);
  return userService.userStream(currentUser.uid);
});

// ── Current User Data — future provider (for splash, login flow) ──────────────
final currentUserDataProvider = FutureProvider<UserModel?>((ref) async {
  ref.watch(mockUserTickProvider);
  if (mockUser != null) return mockUser;

  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;
  final userService = ref.watch(userServiceProvider);
  return userService.fetchUserById(currentUser.uid);
});

// ── User Model by ID — family stream ─────────────────────────────────────────
final userModelStreamProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) {
  ref.watch(mockUserTickProvider);
  final userService = ref.watch(userServiceProvider);
  return userService.userStream(userId);
});

// ── Current User Role — derived from stream (cached, no duplicate fetch) ──────
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  return userAsync.valueOrNull?.role;
});

// ── Auth loading state ────────────────────────────────────────────────────────
final authLoadingProvider = StateProvider<bool>((ref) => false);

// ── Mock user tick — internal trigger used by every provider that
// exposes the current user. Reading it bumps the Riverpod graph
// whenever [mockUser] is reassigned, so consumers rebuild live.
//
// We use a plain `Provider` (not `StateProvider`) so its build
// function reads the current `mockUserTickSeed` global every time
// it is rebuilt. The state-default value is irrelevant — every
// call to `setMockUser()` invalidates both the listener and the
// provider so the next read goes through this factory fresh.
final mockUserTickProvider = Provider<int>((ref) {
  ref.watch(mockUserTickListenerProvider);
  return mockUserTickSeed;
});

/// Companion StateProvider — `setMockUser()` increments this so
/// every consumer of [mockUserTickProvider] rebuilds and reads
/// the current [mockUserTickSeed] value.
final mockUserTickListenerProvider = StateProvider<int>(
  (_) => mockUserTickSeed,
);

// ── Auth refresh listenable ──────────────────────────────────────────────────
//
// `appRouter.refreshListenable` needs a `Listenable` that ticks
// whenever auth state flips (sign-in / sign-out / role swap /
// account swap) so the redirect rule re-runs without an explicit
// navigation event.
//
// This is a *plain* Provider<ChangeNotifier>, NOT a
// ChangeNotifierProvider — a ChangeNotifierProvider would rebuild
// the listener itself on every notifyListeners, which would
// re-create the router and reset navigation. A plain Provider
// exposes the same ChangeNotifier instance for the lifetime of
// the container so it can safely drive refreshListenable.
class AuthRefreshNotifier extends ChangeNotifier {
  // `notifyListeners()` is deferred to a microtask so it does not
  // fire while Riverpod is still iterating its dependency graph
  // (which causes `ConcurrentModificationError` on
  // `_HashMap<ProviderElementBase, ...>` inside the
  // `visitAncestors` rebuild loop). The re-entrancy guard
  // collapses bursts of state flips into a single notification.
  bool _scheduled = false;

  AuthRefreshNotifier(Ref ref) {
    // Re-run the redirect on every Firebase auth flip, every
    // current-user stream emission, and every demo-user swap.
    // The subscriptions keep those providers alive from app start
    // — that is what makes the redirect reactive.
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, __) {
      _scheduleNotify();
    });
    ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (_, __) {
        _scheduleNotify();
      },
    );
    ref.listen<int>(mockUserTickProvider, (_, __) {
      _scheduleNotify();
    });
  }

  void _scheduleNotify() {
    if (_scheduled) return;
    _scheduled = true;
    Future<void>.microtask(() {
      _scheduled = false;
      notifyListeners();
    });
  }
}

final authRefreshProvider = Provider<AuthRefreshNotifier>((ref) {
  final notifier = AuthRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ── AuthController (Notifier) — single source of truth for sign-out ──────────
//
// `authControllerProvider.notifier.signOut()` is the only sanctioned
// way for widgets to log the user out. It centralises the
// `setMockUser(null)` + provider invalidations + Firebase
// `signOut()` sequence so callers don't have to remember the
// fragile dance. Navigation is intentionally *not* triggered here —
// the router's redirect picks up the auth-state flip via
// [authRefreshProvider] and sends the user to `/login`.
class AuthController extends Notifier<void> {
  @override
  void build() {}

  Future<void> signOut() async {
    setMockUser(null);                       // bumps mock tick -> refresh notifier fires
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    ref.invalidate(currentUserStreamProvider);
    ref.invalidate(currentUserDataProvider);
    // `AuthService.signOut()` is a no-op when Firebase is not
    // initialised (so tests / cold-start race windows don't throw).
    await ref.read(authServiceProvider).signOut();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, void>(AuthController.new);

// Mock Firebase User implementation for offline/demo support
class MockFirebaseUser implements User {
  @override
  final String uid;

  @override
  final String? email;

  MockFirebaseUser(this.uid, this.email);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
