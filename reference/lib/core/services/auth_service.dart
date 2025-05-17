import 'package:firebase_auth/firebase_auth.dart';
import 'package:movieverse/core/services/firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firebaseService =
      FirebaseService(); // Assuming FirebaseService is defined elsewhere

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _firebaseService.logEvent('user_signup', {
        'method': 'email',
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result;
    } catch (e) {
      _firebaseService.logEvent('signup_error', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _firebaseService.logEvent('user_login', {
        'method': 'email',
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result;
    } catch (e) {
      _firebaseService.logEvent('login_error', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _firebaseService.logEvent('user_logout', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _firebaseService.logEvent('logout_error', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user has been disabled.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return 'An error occurred. Please try again.';
  }
}
