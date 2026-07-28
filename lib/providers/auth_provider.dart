import 'package:firebase_auth/firebase_auth.dart';
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
