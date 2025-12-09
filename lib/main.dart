// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/provider/provider_main_screen.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with robust error handling
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Handle duplicate app error or any other Firebase initialization errors
    // If Firebase is already initialized (e.g., via auto-initialization on Android),
    // this will catch the error and allow the app to continue
    if (e.toString().contains('duplicate-app') ||
        e.toString().contains('already exists')) {
      // Firebase is already initialized, which is fine
      // Try to get the default app to verify it exists
      try {
        Firebase.app();
      } catch (_) {
        // If we can't get the app, something is wrong
        rethrow;
      }
    } else {
      // Re-throw other errors as they might be important
      rethrow;
    }
  }

  runApp(const QuickFixApp());
}

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickFix',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. If waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If user is logged in
        if (snapshot.hasData) {
          // Fetch user profile to determine role
          return FutureBuilder<UserModel?>(
            future: authService.getUserProfile(),
            builder: (context, profileSnapshot) {
              // Handle loading state
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Handle error state - if profile fetch fails, show error and allow retry
              if (profileSnapshot.hasError) {
                final error = profileSnapshot.error;
                // Check if it's a timeout or network error
                final isTimeoutError =
                    error.toString().contains('TimeoutException') ||
                    error.toString().contains('timeout');

                // Show error message to user instead of immediately logging out
                // Only log out if it's a persistent error after retries
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isTimeoutError
                                ? 'Connection Timeout'
                                : 'Error Loading Profile',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isTimeoutError
                                ? 'Unable to connect to the server. Please check your internet connection and try again.'
                                : 'Failed to load your profile. Please try logging in again.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              // Log out and return to login screen
                              authService.logout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B84FF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Return to Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Handle successful data fetch
              if (profileSnapshot.hasData && profileSnapshot.data != null) {
                final user = profileSnapshot.data!;
                if (user.userType == 'provider') {
                  return const ProviderMainScreen();
                } else {
                  return const MainScreen();
                }
              }

              // Fallback if profile fetch returns null (e.g. deleted from DB but in Auth)
              // Log out to prevent infinite loop
              authService.logout();
              return const LoginScreen();
            },
          );
        }

        // 3. If user is NOT logged in
        return const LoginScreen();
      },
    );
  }
}
