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
//
// Reads the Firebase Auth cached user FIRST (synchronous, no async gap),
// then falls back to the stream value. This prevents the GoRouter redirect
// from seeing `null` during the ~200ms window before authStateChanges() emits.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(mockUserTickProvider);
  if (mockUser != null) {
    return MockFirebaseUser(mockUser!.userId, mockUser!.email);
  }
  // Priority 1: synchronous SDK cache (available immediately on cold start).
  final cached = ref.watch(authServiceProvider).currentUser;
  if (cached != null) return cached;
  // Priority 2: stream value (updated on auth state changes).
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

  // HARD FIX: pull the cached Firebase User AND the stream value
  // so the stream rebuilds when the auth state flips mid-session
  // (e.g. a real user signs in after we already emitted `null`
  // for the unauthenticated state). The previous implementation
  // only watched `currentUserProvider` — which is `null` while
  // AsyncLoading — and the redirect logic could settle on `null`
  // for the lifetime of the stream.
  final firebaseUser = ref.watch(authServiceProvider).currentUser;
  final streamUser = ref.watch(authStateProvider).value;
  final currentUser = firebaseUser ?? streamUser;
  if (currentUser == null) return Stream.value(null);
  final userService = ref.watch(userServiceProvider);
  return userService.userStream(currentUser.uid);
});

// ── Current User Data — future provider (for splash, login flow) ──────────────
final currentUserDataProvider = FutureProvider<UserModel?>((ref) async {
  // Keep alive across the entire app lifetime so the router's
  // refreshListenable can re-read the resolved value at any
  // moment without a re-fetch (which would race with the next
  // navigation event and cause the "redirect → login → redirect"
  // loop we just fixed).
  ref.keepAlive();
  ref.watch(mockUserTickProvider);
  if (mockUser != null) return mockUser;

  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;
  final userService = ref.watch(userServiceProvider);
  // HARD FIX: `currentUser.email` can be null for accounts that
  // authenticated via phone or anonymous providers. Fall back to
  // an empty string so `fetchUserById`'s email lookup branch
  // still runs (the UID lookup will succeed first).
  final email = currentUser.email ?? '';
  return userService.fetchUserById(currentUser.uid, email: email);
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

// ── Auth session — single source of truth used by the router redirect ─────────
//
// The router calls this synchronously on every navigation event.
// It returns a record of (isSignedIn, UserModel?).
// Using the FIREBASE AUTH cached state (not the Firestore stream)
// to determine `isSignedIn` prevents the race where the stream is
// still AsyncLoading and the router kicks the user to /login.
//
// The UserModel is read from the stream so role-based redirects
// still work — but crucially, `isSignedIn` does NOT depend on the
// UserModel being loaded yet.
//
// HARD FIX: accept the parameter as `dynamic` so callers from
// BOTH widget scope (`WidgetRef`) and provider scope (`Ref<T>`,
// `ProviderRef<T>`) can invoke this without an explicit cast.
//
// Why `dynamic` here is safe: we only call `.read(provider)` on
// the ref, and every Riverpod ref class (`WidgetRef`, `Ref`,
// `ProviderRef`) exposes a `.read<T>(ProviderListenable<T>) => T`
// method. We then assign the result to a typed local — `dynamic`
// is never actually returned to the caller.
({bool isSignedIn, UserModel? userModel}) readAuthSession(dynamic ref) {
  if (mockUser != null) return (isSignedIn: true, userModel: mockUser);

  // Read the Firebase Auth user synchronously. The cached value
  // is available immediately on cold start, so this branch is the
  // most reliable source of truth for "is the user signed in?".
  final firebaseUserCached =
      ref.read(authServiceProvider).currentUser;
  final authStreamUser = ref.read(authStateProvider).value;
  final firebaseUser = firebaseUserCached ?? authStreamUser;
  final isSignedIn = firebaseUser != null;

  // HARD FIX: only return a userModel whose UID matches the
  // currently signed-in Firebase user. The previous code returned
  // *any* resolved UserModel — including a stale value from the
  // previously signed-in account — which the router then used to
  // decide where to send the new user. That mismatch caused the
  // "logged in, then bounced back to /login" loop.
  UserModel? readUserModelForCurrentUser() {
    if (firebaseUser == null) return null;
    final currentUid = firebaseUser.uid;

    // Prefer the cached future provider value (always kept alive).
    try {
      final v = ref.read(currentUserDataProvider).valueOrNull;
      if (v is UserModel && v.userId == currentUid) return v;
    } on Object {/* ignore */}

    // Then check the live stream's cached value.
    try {
      final v = ref.read(currentUserStreamProvider).valueOrNull;
      if (v is UserModel && v.userId == currentUid) return v;
    } on Object {/* ignore */}

    return null;
  }

  final userModel = readUserModelForCurrentUser();
  return (isSignedIn: isSignedIn, userModel: userModel);
}

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
    // ── HARD FIX: also listen on the future provider so the router
    // re-runs its redirect when the FutureProvider resolves to a
    // UserModel after the initial AsyncLoading state. Without
    // this, the redirect sees an AsyncLoading backend and may
    // bounce the user back to /login even though the data is on
    // its way.
    ref.listen<AsyncValue<UserModel?>>(
      currentUserDataProvider,
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
