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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

              // Handle error state - if profile fetch fails, log out and show login
              if (profileSnapshot.hasError) {
                // Log out the user if profile fetch fails
                authService.logout();
                return const LoginScreen();
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
