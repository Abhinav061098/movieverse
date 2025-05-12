import 'package:flutter/foundation.dart';

class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String gender;
  final DateTime dob;
  final String country;
  final String? profileImageUrl;

  UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    required this.gender,
    required this.dob,
    required this.country,
    this.profileImageUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime parseDob() {
      try {
        final dobValue = map['dob'];
        if (dobValue is String) {
          return DateTime.parse(dobValue);
        } else if (dobValue is DateTime) {
          return dobValue;
        }
        return DateTime(2000);
      } catch (e) {
        debugPrint('Error parsing dob: $e');
        return DateTime(2000);
      }
    }
    return UserProfile(
      uid: map['uid']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      gender: map['gender']?.toString() ?? 'Not specified',
      dob: parseDob(),
      country: map['country']?.toString() ?? 'Not specified',
      profileImageUrl: map['profileImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'gender': gender,
      'dob': dob.toIso8601String(),
      'country': country,
      'profileImageUrl': profileImageUrl,
      'profile_setup': true,
    };
  }

  UserProfile copyWith({
    String? username,
    String? email,
    String? gender,
    DateTime? dob,
    String? country,
    String? profileImageUrl,
  }) {
    return UserProfile(
      uid: uid,
      username: username ?? this.username,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      country: country ?? this.country,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
