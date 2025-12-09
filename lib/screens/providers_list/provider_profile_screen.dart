import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

class ProviderProfileScreen extends StatefulWidget {
  final UserModel? provider;

  const ProviderProfileScreen({super.key, this.provider});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  late final String _uid;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _rateController;
  late TextEditingController _aboutController;
  String? _selectedCategory;

  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // If provider is passed, use their ID, otherwise use current user's ID
    _uid = widget.provider?.id ?? FirebaseAuth.instance.currentUser!.uid;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // 1. Fetch current data once to populate fields
    final userStream = _dbService.getUserStream(_uid);
    final user = await userStream.first;

    if (user != null) {
      _currentUser = user;
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
      _phoneController = TextEditingController(text: user.phone);
      _rateController = TextEditingController(
        text: user.rate?.toString() ?? '',
      );
      _aboutController = TextEditingController(text: user.about ?? '');
      _selectedCategory = user.category;
    } else {
      // Fallback init
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _rateController = TextEditingController();
      _aboutController = TextEditingController();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    final updatedUser = UserModel(
      id: _uid,
      email: _emailController
          .text, // Note: Changing email here doesn't update Auth email
      name: _nameController.text,
      phone: _phoneController.text,
      userType: 'provider',
      category: _selectedCategory,
      rate: double.tryParse(_rateController.text),
      about: _aboutController.text,
      imageUrl: _currentUser!.imageUrl, // Keep existing image
      rating: _currentUser!.rating,
      reviewCount: _currentUser!.reviewCount,
      isAvailable: _currentUser!.isAvailable,
    );

    try {
      await _dbService.updateUserProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel("Full Name"),
              _buildTextField(_nameController),
              const SizedBox(height: 16),
              _buildLabel("Phone"),
              _buildTextField(_phoneController),
              const SizedBox(height: 16),
              _buildLabel("Hourly Rate (₱)"),
              _buildTextField(_rateController, isNumber: true),
              const SizedBox(height: 16),
              _buildLabel("About"),
              _buildTextField(_aboutController, maxLines: 4),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B84FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(
    TextEditingController controller, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
