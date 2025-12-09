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
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://quick-fix-89d7f-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // Cache to prevent multiple simultaneous profile fetches
  UserModel? _cachedProfile;
  String? _cachedUid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Clear cache on logout
  void _clearCache() {
    _cachedProfile = null;
    _cachedUid = null;
  }

  Future<UserModel?> getUserProfile({int retryCount = 2}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _clearCache();
      return null;
    }

    // Return cached profile if same user
    if (_cachedUid == user.uid && _cachedProfile != null) {
      return _cachedProfile;
    }

    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
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
          final profile = UserModel.fromMap(
            snapshot.value as Map<dynamic, dynamic>,
            user.uid,
          );

          // Cache the profile
          _cachedProfile = profile;
          _cachedUid = user.uid;

          return profile;
        }

        return null;
      } on TimeoutException catch (e) {
        print(
          "Error fetching user profile (attempt ${attempt + 1}/${retryCount + 1}): $e",
        );
        if (attempt == retryCount) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } catch (e) {
        print("Error fetching user profile: $e");
        if (e.toString().contains('Permission denied') ||
            e.toString().contains('network')) {
          if (attempt == retryCount) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        } else {
          rethrow;
        }
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
    String? category,
    String? rate,
    String? about,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

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

      await _db.ref('users/$uid').set(newUser.toMap());

      // Immediately log out after registration to prevent auto-login issues
      await logout();

      return {'success': true, 'message': 'Account created successfully!'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String expectedRole,
  ) async {
    try {
      // Clear any existing cache first
      _clearCache();

      // Sign In
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Add a small delay to ensure Firebase is ready
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final snapshot = await _db
            .ref('users/$uid')
            .get()
            .timeout(const Duration(seconds: 10));

        if (snapshot.exists && snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final String role = data['userType'] ?? 'seeker';

          print('DEBUG: User role from DB: $role, Expected: $expectedRole');

          // Verify Role Matches
          if (role != expectedRole) {
            await logout(); // This will clear cache too

            final roleDisplay = role == 'provider'
                ? 'Service Provider'
                : 'Service Seeker';
            final expectedDisplay = expectedRole == 'provider'
                ? 'Service Provider'
                : 'Service Seeker';

            return {
              'success': false,
              'message':
                  'This account is registered as a $roleDisplay. Please switch to the $roleDisplay tab to login.',
            };
          }

          // Cache the profile for immediate use
          _cachedProfile = UserModel.fromMap(data, uid);
          _cachedUid = uid;
        } else {
          print('WARNING: Auth user exists but no DB record found');
          await logout();
          return {
            'success': false,
            'message': 'Account data not found. Please contact support.',
          };
        }
      } on TimeoutException {
        print('Timeout fetching user profile during login');
        // Don't log out on timeout - let AuthWrapper handle it
        return {
          'success': false,
          'message':
              'Connection timeout. Please check your internet and try again.',
        };
      }

      return {'success': true, 'message': 'Login successful!'};
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Please try again later.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else {
        message = e.message ?? 'Login failed.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  Future<void> logout() async {
    _clearCache();
    await _auth.signOut();
  }
}
