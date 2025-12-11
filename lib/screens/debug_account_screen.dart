// Add this as a temporary debug screen
// lib/screens/debug_account_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class DebugAccountScreen extends StatefulWidget {
  const DebugAccountScreen({super.key});

  @override
  State<DebugAccountScreen> createState() => _DebugAccountScreenState();
}

class _DebugAccountScreenState extends State<DebugAccountScreen> {
  final _emailController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Future<void> _checkAccount() async {
    if (_emailController.text.isEmpty) {
      setState(() => _result = 'Please enter an email');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Checking...';
    });

    try {
      // Try to find user by email in database
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://quick-fix-89d7f-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      final snapshot = await db.ref('users').get();

      if (snapshot.exists) {
        final users = _asMap(snapshot.value);
        String foundInfo = '';

        users.forEach((uid, userData) {
          final data = _asMap(userData);
          if (data['email'] == _emailController.text) {
            foundInfo =
                '''
Found account!
UID: $uid
Email: ${data['email']}
Name: ${data['name']}
UserType: ${data['userType']}
Phone: ${data['phone']}
${data['category'] != null ? 'Category: ${data['category']}' : ''}
${data['rate'] != null ? 'Rate: ${data['rate']}' : ''}
''';
          }
        });

        setState(() {
          _result = foundInfo.isEmpty
              ? 'No account found with email: ${_emailController.text}'
              : foundInfo;
          _isLoading = false;
        });
      } else {
        setState(() {
          _result = 'No users in database';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fixUserType(String email, String newUserType) async {
    setState(() {
      _isLoading = true;
      _result = 'Fixing...';
    });

    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://quick-fix-89d7f-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      final snapshot = await db.ref('users').get();

      if (snapshot.exists) {
        final users = _asMap(snapshot.value);

        users.forEach((uid, userData) async {
          final data = _asMap(userData);
          if (data['email'] == email) {
            await db.ref('users/$uid').update({'userType': newUserType});
            setState(() {
              _result =
                  'Updated userType to: $newUserType\nPlease try logging in again.';
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error fixing: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Account Check'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the email of the account you\'re having trouble with:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B84FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Check Account',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
            const SizedBox(height: 24),
            if (_result.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_result),
              ),
              const SizedBox(height: 16),
              if (_result.contains('UserType:')) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _fixUserType(
                                _emailController.text,
                                'provider',
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Fix to Provider',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () =>
                                  _fixUserType(_emailController.text, 'seeker'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text(
                          'Fix to Seeker',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
