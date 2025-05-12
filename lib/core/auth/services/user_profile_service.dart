import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final _db = FirebaseDatabase.instance.ref();
  final _maxRetries = 3;

  Future<UserProfile?> fetchProfile(String uid) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        debugPrint('Fetching profile for user $uid (attempt ${retryCount + 1})');
        final snapshot = await _db.child('users/$uid').get();

        debugPrint('Snapshot exists: ${snapshot.exists}');
        debugPrint('Snapshot value: ${snapshot.value}');

        if (!snapshot.exists) {
          debugPrint('No profile found for user $uid');
          return null;
        }

        if (snapshot.value == null) {
          debugPrint('Profile data is null for user $uid');
          return null;
        }

        // Prevent pigeon error: check type before casting
        if (snapshot.value is! Map) {
          debugPrint('Pigeon error: Data at users/$uid is not a Map. Actual value: ${snapshot.value}');
          throw Exception(
              'Profile data is not a Map (object). Actual type: ${snapshot.value.runtimeType}.\n' +
              'This usually means the data at /users/$uid in your Firebase Realtime Database is an array or list, not an object.\n' +
              'Please delete the /users/$uid node in your database and try again.');
        }
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('Profile data is a Map: ${data}');
        return UserProfile.fromMap(data);
      } catch (e, stack) {
        retryCount++;
        debugPrint('Error fetching profile (attempt $retryCount): $e\n$stack');
        if (retryCount >= _maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    return null;
  }

  Future<void> updateProfile(UserProfile profile) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        debugPrint(
            'Updating profile for user ${profile.uid} (attempt ${retryCount + 1})');

        final ref = _db.child('users/${profile.uid}');

        // Prepare the complete profile data
        final data = {
          ...profile.toMap(),
          'created_at': ServerValue.timestamp,
          'updated_at': ServerValue.timestamp,
          'last_login': ServerValue.timestamp,
          'profile_setup': true,
        };

        debugPrint('Saving profile data: $data');

        // Create new profile with set
        await ref.set(data);

        // Verify write was successful
        final snapshot = await ref.get();
        if (!snapshot.exists || snapshot.value == null) {
          throw Exception('Profile update failed - data not found after write');
        }

        final savedData = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('Saved data: $savedData');

        // Verify profile_setup flag is set
        if (savedData['profile_setup'] != true) {
          throw Exception(
              'Profile update failed - profile_setup flag not set to true');
        }

        debugPrint('Profile updated successfully');
        return;
      } catch (e, stack) {
        retryCount++;
        debugPrint('Error updating profile (attempt $retryCount): $e\n$stack');
        if (retryCount >= _maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }

  Future<void> testDatabaseConnection() async {
    try {
      debugPrint('Testing database connection...');
      debugPrint('Database URL: ${FirebaseDatabase.instance.databaseURL}');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Error: No authenticated user');
        return;
      }

      final testRef = _db.child('users/${user.uid}/test');
      await testRef.set({
        'timestamp': ServerValue.timestamp,
        'test': 'Connection successful'
      });

      final snapshot = await testRef.get();
      debugPrint('Test write successful: ${snapshot.value}');

      await testRef.remove();
    } catch (e) {
      debugPrint('Database test failed: $e');
      if (e.toString().contains('Permission denied')) {
        debugPrint('Error indicates a rules issue');
      } else if (e.toString().contains('network')) {
        debugPrint('Error indicates a connection issue');
      }
      rethrow;
    }
  }
}
