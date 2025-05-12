import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  late final FirebaseAnalytics analytics;
  bool _initialized = false;
  StreamSubscription<User?>? _authStateSubscription;

  factory FirebaseService() => _instance;
  FirebaseService._internal() {
    debugPrint('FirebaseService: Creating instance');
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('Initializing Firebase...');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set the database URL
      FirebaseDatabase.instance.databaseURL =
          'https://movieverse-bd77e-default-rtdb.asia-southeast1.firebasedatabase.app';

      // Enable persistence for offline capabilities
      FirebaseDatabase.instance
          .setPersistenceEnabled(true); // Initialize Analytics
      analytics = FirebaseAnalytics.instance;
      debugPrint('FirebaseService: Analytics initialized');

      // Set up auth state listener
      _setupAuthStateListener();

      // Wait for auth state to be ready and check current user
      final auth = FirebaseAuth.instance;
      debugPrint('Current auth state: ${auth.currentUser?.uid}');

      // Create initial profile if user is authenticated
      if (auth.currentUser != null) {
        await _createInitialUserProfile(auth.currentUser!);
      }

      _initialized = true;
      debugPrint('Firebase fully initialized');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }

  void _setupAuthStateListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        debugPrint('Auth state changed: User logged in ${user.uid}');
        await _createInitialUserProfile(user);
      } else {
        debugPrint('Auth state changed: User logged out');
      }
    }, onError: (error) {
      debugPrint('Auth state error: $error');
    });
  }

  Future<void> _createInitialUserProfile(User user) async {
    try {
      final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        debugPrint(
            'No profile exists yet for user ${user.uid}, skipping initial profile creation.');
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (data['profile_setup'] == true) {
        await userRef.update({'last_login': ServerValue.timestamp});
        debugPrint('Updated last login for user ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error in _createInitialUserProfile: $e');
    }
  }

  // Test database connection
  Future<void> testDatabaseConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Database test failed: No authenticated user');
        return;
      }

      // Test write to user's path
      final ref =
          FirebaseDatabase.instance.ref('users/${user.uid}/connection_test');
      await ref.set({'timestamp': ServerValue.timestamp, 'test': true});

      // Verify the write
      final snapshot = await ref.get();
      debugPrint('Database connection test result: ${snapshot.value}');

      // Clean up test data
      await ref.remove();
      debugPrint('Database connection test successful');
    } catch (e) {
      debugPrint('Database connection test failed: $e');
      rethrow;
    }
  }

  // Analytics Methods
  Future<void> logScreenView(String screenName) async {
    try {
      await analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  Future<void> logEvent(
      String eventName, Map<String, dynamic> parameters) async {
    try {
      await analytics.logEvent(
        name: eventName,
        parameters: parameters.cast<String, Object>(),
      );
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }
}
