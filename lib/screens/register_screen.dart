import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Service Seeker
  final _seekerNameController = TextEditingController();
  final _seekerEmailController = TextEditingController();
  final _seekerPhoneController = TextEditingController();
  final _seekerPasswordController = TextEditingController();
  final _seekerConfirmPasswordController = TextEditingController();

  // Controllers for Provider
  final _providerNameController = TextEditingController();
  final _providerEmailController = TextEditingController();
  final _providerPhoneController = TextEditingController();
  final _providerPasswordController = TextEditingController();
  final _rateController = TextEditingController();
  final _aboutController = TextEditingController();

  String? _selectedCategory;
  bool _isServiceSeeker = true; // true = Service Seeker, false = Provider
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> categories = [
    'Plumbing',
    'Electrical',
    'Home Cleaning',
    'Appliance Repair',
    'Tutoring',
    'Painting',
  ];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for Service Seeker
    if (_isServiceSeeker) {
      if (_seekerPasswordController.text !=
          _seekerConfirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isServiceSeeker
                ? 'Service Seeker account created!'
                : 'Provider account created!',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _seekerNameController.dispose();
    _seekerEmailController.dispose();
    _seekerPhoneController.dispose();
    _seekerPasswordController.dispose();
    _seekerConfirmPasswordController.dispose();
    _providerNameController.dispose();
    _providerEmailController.dispose();
    _providerPhoneController.dispose();
    _providerPasswordController.dispose();
    _rateController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.arrow_back_ios,
                                size: 16,
                                color: Colors.black54,
                              ),
                              Text(
                                'Back to login',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Logo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B84FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.handyman,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "QuickFix",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "Create an account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Join QuickFix to find or offer services",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // Tab selector
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isServiceSeeker = true;
                                  _formKey.currentState?.reset();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isServiceSeeker
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: _isServiceSeeker
                                      ? Border.all(
                                          color: const Color(0xFF0B84FF),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 18,
                                      color: _isServiceSeeker
                                          ? const Color(0xFF0B84FF)
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Service Seeker',
                                      style: TextStyle(
                                        color: _isServiceSeeker
                                            ? const Color(0xFF0B84FF)
                                            : Colors.black54,
                                        fontWeight: _isServiceSeeker
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isServiceSeeker = false;
                                  _formKey.currentState?.reset();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isServiceSeeker
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: !_isServiceSeeker
                                      ? Border.all(
                                          color: const Color(0xFF0B84FF),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.work,
                                      size: 18,
                                      color: !_isServiceSeeker
                                          ? const Color(0xFF0B84FF)
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Provider',
                                      style: TextStyle(
                                        color: !_isServiceSeeker
                                            ? const Color(0xFF0B84FF)
                                            : Colors.black54,
                                        fontWeight: !_isServiceSeeker
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Conditional form based on selection
                    if (_isServiceSeeker)
                      _buildServiceSeekerForm()
                    else
                      _buildProviderForm(),

                    const SizedBox(height: 24),

                    // Register button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B84FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Sign in",
                            style: TextStyle(
                              color: Color(0xFF0B84FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Service Seeker Form
  Widget _buildServiceSeekerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel("Full Name"),
        _buildTextField(
          controller: _seekerNameController,
          hint: "Juan Dela Cruz",
        ),
        const SizedBox(height: 16),

        _buildLabel("Email"),
        _buildTextField(
          controller: _seekerEmailController,
          hint: "you@example.com",
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        _buildLabel("Phone Number"),
        _buildTextField(
          controller: _seekerPhoneController,
          hint: "0917-123-4567",
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        _buildLabel("Password"),
        TextFormField(
          controller: _seekerPasswordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            hint: "Create a password",
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.black38,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) => value!.length < 6 ? "Min 6 characters" : null,
        ),
        const SizedBox(height: 16),

        _buildLabel("Confirm Password"),
        TextFormField(
          controller: _seekerConfirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: _inputDecoration(
            hint: "Confirm your password",
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.black38,
              ),
              onPressed: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
          ),
          validator: (value) {
            if (value!.isEmpty) return "Please confirm your password";
            if (value != _seekerPasswordController.text) {
              return "Passwords do not match";
            }
            return null;
          },
        ),
      ],
    );
  }

  // Provider Form
  Widget _buildProviderForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel("Full Name"),
        _buildTextField(
          controller: _providerNameController,
          hint: "Juan Dela Cruz",
        ),
        const SizedBox(height: 16),

        _buildLabel("Email"),
        _buildTextField(
          controller: _providerEmailController,
          hint: "juan@email.com",
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        _buildLabel("Phone"),
        _buildTextField(
          controller: _providerPhoneController,
          hint: "0917-123-4567",
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        _buildLabel("Password"),
        TextFormField(
          controller: _providerPasswordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            hint: "•••••••",
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.black38,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) => value!.length < 6 ? "Min 6 characters" : null,
        ),
        const SizedBox(height: 16),

        _buildLabel("Service Category"),
        DropdownButtonFormField(
          value: _selectedCategory,
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedCategory = value);
          },
          decoration: _inputDecoration(),
          validator: (value) =>
              value == null ? "Please select a category" : null,
        ),
        const SizedBox(height: 16),

        _buildLabel("Hourly Rate (₱)"),
        _buildTextField(
          controller: _rateController,
          hint: "500",
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 16),

        _buildLabel("About Your Service"),
        TextFormField(
          controller: _aboutController,
          maxLines: 4,
          decoration: _inputDecoration(
            hint: "Tell customers about your experience and services...",
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel("Profile Photo"),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload, size: 32, color: Colors.black38),
                SizedBox(height: 8),
                Text("Click to upload your profile photo"),
                Text(
                  "PNG, JPG up to 10MB",
                  style: TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // UI Helpers
  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: _inputDecoration(hint: hint),
      validator: (value) =>
          value!.isEmpty ? "This field cannot be empty" : null,
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0B84FF), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
