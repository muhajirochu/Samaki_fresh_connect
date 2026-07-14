import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';

// ── Service Providers ─────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Overridden in main.dart with the already-initialized instance (BUG-04 fix).
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

// Global offline mock user variable (shared across all ProviderContainers and GoRouter)
UserModel? mockUser;

// ── Firebase Auth Stream ───────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  if (mockUser != null) {
    return Stream.value(MockFirebaseUser(mockUser!.userId, mockUser!.email));
  }
  final authService = ref.watch(authServiceProvider);
  return authService.authStateStream;
});

// ── Current Firebase User (reactive) ────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  if (mockUser != null) {
    return MockFirebaseUser(mockUser!.userId, mockUser!.email);
  }
  return ref.watch(authStateProvider).value;
});

// ── Current User Data — real-time stream (preferred over FutureProvider) ──────
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  if (mockUser != null) return Stream.value(mockUser);

  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);
  final userService = ref.watch(userServiceProvider);
  return userService.userStream(currentUser.uid);
});

// ── Current User Data — future provider (for splash, login flow) ──────────────
final currentUserDataProvider = FutureProvider<UserModel?>((ref) async {
  if (mockUser != null) return mockUser;

  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;
  final userService = ref.watch(userServiceProvider);
  return userService.fetchUserById(currentUser.uid);
});

// ── User Model by ID — family stream ─────────────────────────────────────────
final userModelStreamProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) {
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
