import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Register method
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.post(
      //   Uri.parse('YOUR_API_URL/register'),
      //   body: json.encode({
      //     'name': name,
      //     'email': email,
      //     'phone': phone,
      //     'password': password,
      //     'userType': userType,
      //   }),
      // );

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful registration
      return {'success': true, 'message': 'Account created successfully!'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed. Please try again.',
      };
    }
  }

  // Login method
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String userType,
  ) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful login
      _currentUser = User(
        id: '123',
        email: email,
        name: 'John Doe',
        userType: userType,
      );

      return {'success': true, 'message': 'Login successful!'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed. Please check your credentials.',
      };
    }
  }

  // Logout method
  Future<void> logout() async {
    _currentUser = null;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _currentUser != null;
  }
}
