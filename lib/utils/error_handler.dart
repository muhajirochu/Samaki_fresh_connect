import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getFirebaseAuthErrorMessage(error);
    }

    if (error is String) {
      return error;
    }

    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }

    return 'An unexpected error occurred';
  }

  static String getFirebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection');
  }

  static bool isAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('auth') || errorString.contains('unauthorized');
  }

  static bool isNotFoundError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('not found') || errorString.contains('404');
  }

  static bool isServerError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('503');
  }
}
