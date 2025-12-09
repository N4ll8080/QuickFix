import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Configure Firebase Realtime Database with explicit URL
  // If your database is in a specific region, update the URL accordingly
  // Format: https://<project-id>-default-rtdb.<region>.firebasedatabase.app
  // For default region: https://<project-id>-default-rtdb.firebaseio.com
  // Note: If this URL doesn't work, check your Firebase Console > Realtime Database > Data tab for the correct URL
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://quick-fix-89d7f-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // Stream for Auth State Changes (used in main.dart)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fetch current user profile from Realtime Database
  Future<UserModel?> getUserProfile({int retryCount = 2}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        // Increase timeout to 15 seconds and add retry logic
        final snapshot = await _db
            .ref('users/${user.uid}')
            .get()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'Profile fetch timed out after 15 seconds',
                );
              },
            );

        if (snapshot.exists && snapshot.value != null) {
          return UserModel.fromMap(
            snapshot.value as Map<dynamic, dynamic>,
            user.uid,
          );
        }

        // If snapshot doesn't exist, return null (no retry needed)
        return null;
      } on TimeoutException catch (e) {
        print(
          "Error fetching user profile (attempt ${attempt + 1}/${retryCount + 1}): $e",
        );
        // If this is the last attempt, re-throw the error
        if (attempt == retryCount) {
          rethrow;
        }
        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } catch (e) {
        print("Error fetching user profile: $e");
        // For non-timeout errors, check if it's a network/permission issue
        if (e.toString().contains('Permission denied') ||
            e.toString().contains('network')) {
          // If this is the last attempt, re-throw
          if (attempt == retryCount) {
            rethrow;
          }
          // Wait before retrying
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        } else {
          // For other errors, don't retry
          rethrow;
        }
      }
    }

    return null;
  }

  // Register with Realtime Database support
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
    // Optional provider fields
    String? category,
    String? rate,
    String? about,
  }) async {
    try {
      // 1. Create Auth User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // 2. Prepare Data
      final newUser = UserModel(
        id: uid,
        email: email,
        name: name,
        phone: phone,
        userType: userType,
        category: category,
        rate: rate != null ? double.tryParse(rate) : null,
        about: about,
      );

      // 3. Save to Realtime Database at users/$uid
      await _db.ref('users/$uid').set(newUser.toMap());

      return {'success': true, 'message': 'Account created successfully!'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Login with Role Check
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String expectedRole, // 'seeker' or 'provider'
  ) async {
    try {
      // 1. Sign In
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Fetch User Data to verify Role
      final uid = credential.user!.uid;
      final snapshot = await _db.ref('users/$uid').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final String role = data['userType'] ?? 'seeker';

        // 3. Verify Role Matches Toggle
        if (role != expectedRole) {
          await _auth.signOut(); // Logout if mismatch
          return {
            'success': false,
            'message':
                'Account exists but is registered as a ${role.toUpperCase()}. Please switch tabs.',
          };
        }
      } else {
        // Handle case where auth exists but DB record doesn't (legacy/error)
        // For now, allow entry or force logout
      }

      return {'success': true, 'message': 'Login successful!'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Login failed.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
