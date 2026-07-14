import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/logger.dart';

class AuthService {
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  // Get current user
  User? get currentUser {
    if (!_isFirebaseAvailable) return null;
    return _firebaseAuth.currentUser;
  }

  // Get auth state stream
  Stream<User?> get authStateStream {
    if (!_isFirebaseAvailable) return Stream.value(null);
    return _firebaseAuth.authStateChanges();
  }

  void _ensureFirebaseAvailable() {
    if (!_isFirebaseAvailable) {
      throw StateError(
        'Firebase is not available on this platform. Please use Android or iOS.',
      );
    }
  }

  // Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _ensureFirebaseAvailable();
    try {
      AppLogger.info('Signing up user: $email');

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile
      await userCredential.user?.updateDisplayName(fullName);

      AppLogger.info(
          'User signed up successfully: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign up error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error during sign up: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseAvailable();
    try {
      AppLogger.info('Signing in user: $email');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.info(
          'User signed in successfully: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error during sign in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!_isFirebaseAvailable) return;
    try {
      AppLogger.info('Signing out user');
      await _firebaseAuth.signOut();
      AppLogger.info('User signed out successfully');
    } catch (e) {
      AppLogger.error('Error during sign out: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    _ensureFirebaseAvailable();
    try {
      AppLogger.info('Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Error sending password reset email: ${e.code}');
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error: $e');
      rethrow;
    }
  }

  // Get user ID token
  Future<String?> getIdToken() async {
    if (!_isFirebaseAvailable) return null;
    try {
      final token = await _firebaseAuth.currentUser?.getIdToken();
      return token;
    } catch (e) {
      AppLogger.error('Error getting ID token: $e');
      return null;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated {
    if (!_isFirebaseAvailable) return false;
    return _firebaseAuth.currentUser != null;
  }
}
