import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
//import 'package:cloud_firestore/cloud_firestore.dart'; // Optional: If you want to save extra user data to Firestore later
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Instance of Firebase Auth
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Get current user in your custom User model format
  User? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Note: To get the "userType" (seeker vs provider), you would usually
    // fetch this from a Firestore document associated with this UID.
    // For now, we will default to 'seeker' or handle it via logic.
    return User(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? 'User',
      userType:
          'seeker', // Placeholder: You need Firestore to store userType properly
    );
  }

  // Register method
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      // 1. Create User in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update Display Name
      await credential.user?.updateDisplayName(name);

      // 3. (Optional but Recommended) Save extra data like phone & userType to Firestore
      // await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
      //   'name': name,
      //   'email': email,
      //   'phone': phone,
      //   'userType': userType,
      //   'createdAt': FieldValue.serverTimestamp(),
      // });

      return {'success': true, 'message': 'Account created successfully!'};
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'Registration failed.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Login method
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String userType,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Note: Here you would usually fetch the user document from Firestore
      // to check if the `userType` matches what they selected in the UI.

      return {'success': true, 'message': 'Login successful!'};
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'Login failed.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Logout method
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }
}
