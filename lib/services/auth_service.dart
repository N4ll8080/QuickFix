import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Stream for Auth State Changes (used in main.dart)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fetch current user profile from Realtime Database
  Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Add timeout to prevent infinite loading
      final snapshot = await _db
          .ref('users/${user.uid}')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Profile fetch timed out');
            },
          );

      if (snapshot.exists && snapshot.value != null) {
        return UserModel.fromMap(
          snapshot.value as Map<dynamic, dynamic>,
          user.uid,
        );
      }
    } catch (e) {
      print("Error fetching user profile: $e");
      // Re-throw the error so FutureBuilder can handle it
      rethrow;
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
