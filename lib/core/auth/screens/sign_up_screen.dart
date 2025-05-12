import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignInPressed;
  const SignUpScreen({super.key, required this.onSignInPressed});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _countryController = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('Creating new user account...');
      // Create user in Firebase Auth
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;
      if (user == null) throw Exception('User creation failed');

      debugPrint('User account created. Creating user profile...');
      // Save profile in Realtime Database
      final profile = UserProfile(
        uid: user.uid,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender!,
        dob: _dob!,
        country: _countryController.text.trim(),
        profileImageUrl: null,
      );
      debugPrint('Creating new profile with data: ${profile.toMap()}');

      // Create a fresh profile
      final userProfileService = UserProfileService();
      try {
        debugPrint('About to write user profile to DB: ${profile.toMap()}');
        await userProfileService.updateProfile(profile);
        debugPrint('User profile write to DB succeeded.');
      } catch (dbError) {
        debugPrint('User profile write to DB FAILED: $dbError');
        rethrow;
      }

      // Wait a moment to ensure database consistency
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify the profile
      final verifyRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      final verifySnapshot = await verifyRef.get();

      // Prevent pigeon error: check type before casting
      if (verifySnapshot.value is! Map) {
        debugPrint(
            'Pigeon error: Data at users/${user.uid} is not a Map. Actual value: ${verifySnapshot.value}');
        throw Exception(
            'Profile data is not a Map (object). Actual type: ${verifySnapshot.value.runtimeType}.\n' +
                'This usually means the data at /users/${user.uid} in your Firebase Realtime Database is an array or list, not an object.\n' +
                'Please delete the /users/${user.uid} node in your database and try again.');
      }
      final data = Map<String, dynamic>.from(verifySnapshot.value as Map);
      debugPrint('Verifying saved profile data: $data');

      // Verify all required fields are present
      final requiredFields = [
        'uid',
        'username',
        'email',
        'gender',
        'dob',
        'country',
        'profile_setup'
      ];

      for (final field in requiredFields) {
        if (!data.containsKey(field)) {
          throw Exception(
              'Profile creation failed - missing required field: $field');
        }
      }

      if (data['profile_setup'] != true) {
        throw Exception(
            'Profile creation failed - profile_setup flag not set to true');
      }

      debugPrint('Profile created and verified successfully');

      // Sign out the user since we want them to sign in with their credentials
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful! Please sign in.')),
        );
        // Navigate back to sign in screen
        Navigator.pushReplacementNamed(context, '/sign-in');
      }
    } catch (e) {
      debugPrint('Sign up error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter username' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                  decoration: const InputDecoration(labelText: 'Gender'),
                  validator: (v) => v == null ? 'Select gender' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'Select date',
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: _dob == null
                        ? ''
                        : DateFormat('yyyy-MM-dd').format(_dob!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _dob = picked);
                  },
                  validator: (v) =>
                      _dob == null ? 'Select date of birth' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter country' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Enter valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign Up'),
                ),
                TextButton(
                  onPressed: widget.onSignInPressed,
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
