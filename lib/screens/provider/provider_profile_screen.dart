import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEditMode = false;
  bool _isLoading = true;
  UserModel? _currentUser;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _rateController;
  late TextEditingController _aboutController;

  // Availability
  Map<String, bool> _workingDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<DateTime> _unavailableDates = [];

  @override
  void initState() {
    super.initState();
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 17, minute: 0);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userStream = _dbService.getUserStream(user.uid);
    final userData = await userStream.first;

    if (userData != null) {
      setState(() {
        _currentUser = userData;
        _nameController = TextEditingController(text: userData.name);
        _phoneController = TextEditingController(text: userData.phone);
        _rateController = TextEditingController(
          text: userData.rate?.toString() ?? '',
        );
        _aboutController = TextEditingController(text: userData.about ?? '');

        // Load availability
        if (userData.availability != null) {
          final avail = userData.availability!;
          if (avail['workingDays'] != null) {
            _workingDays = Map<String, bool>.from(avail['workingDays']);
          }
          if (avail['startTime'] != null) {
            final parts = avail['startTime'].toString().split(':');
            _startTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          if (avail['endTime'] != null) {
            final parts = avail['endTime'].toString().split(':');
            _endTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          if (avail['unavailableDates'] != null) {
            _unavailableDates = (avail['unavailableDates'] as List)
                .map((d) => DateTime.parse(d))
                .toList();
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _nameController = TextEditingController();
        _phoneController = TextEditingController();
        _rateController = TextEditingController();
        _aboutController = TextEditingController();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    final updatedUser = UserModel(
      id: _currentUser!.id,
      email: _currentUser!.email,
      name: _nameController.text,
      phone: _phoneController.text,
      userType: 'provider',
      category: _currentUser!.category,
      rate: double.tryParse(_rateController.text),
      about: _aboutController.text,
      imageUrl: _currentUser!.imageUrl,
      rating: _currentUser!.rating,
      reviewCount: _currentUser!.reviewCount,
      isAvailable: _currentUser!.isAvailable,
      availability: {
        'workingDays': _workingDays,
        'startTime': '${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}',
        'endTime': '${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}',
        'unavailableDates': _unavailableDates.map((d) => d.toIso8601String()).toList(),
      },
    );

    try {
      await _dbService.updateUserProfile(updatedUser);
      if (mounted) {
        setState(() => _isEditMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime! : _endTime!,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectUnavailableDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && !_unavailableDates.contains(picked)) {
      setState(() {
        _unavailableDates.add(picked);
      });
    }
  }

  void _removeUnavailableDate(DateTime date) {
    setState(() {
      _unavailableDates.remove(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B84FF)),
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0B84FF),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _isEditMode ? 'Edit Profile' : 'My Profile',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              if (!_isEditMode)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => setState(() => _isEditMode = true),
                )
              else
                TextButton(
                  onPressed: () => setState(() => _isEditMode = false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Profile Picture
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            child: _currentUser!.imageUrl != null &&
                                    _currentUser!.imageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _currentUser!.imageUrl!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                          ),
                          // Verified Badge
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _isEditMode
                                ? TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                  )
                                : Text(
                                    _currentUser!.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                            const SizedBox(height: 6),
                            Text(
                              _currentUser!.category ?? "Service Provider",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < _currentUser!.rating.floor()
                                        ? Icons.star
                                        : (index < _currentUser!.rating
                                            ? Icons.star_half
                                            : Icons.star_border),
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  "${_currentUser!.rating.toStringAsFixed(1)} (${_currentUser!.reviewCount})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _currentUser!.isAvailable
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _currentUser!.isAvailable ? "Available" : "Busy",
                                style: TextStyle(
                                  color: _currentUser!.isAvailable
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Personal Information Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildEditableRow(
                        "Phone Number",
                        _phoneController,
                        Icons.phone,
                      ),
                      const SizedBox(height: 20),
                      _buildEditableRow(
                        "Hourly Rate",
                        _rateController,
                        Icons.attach_money,
                        isNumber: true,
                      ),
                      const SizedBox(height: 20),
                      _buildEditableRow(
                        "About",
                        _aboutController,
                        Icons.info_outline,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Availability Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Availability",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (_isEditMode)
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Color(0xFF0B84FF)),
                              onPressed: _selectUnavailableDate,
                              tooltip: 'Add unavailable date',
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Working Days
                      const Text(
                        "Working Days",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _workingDays.entries.map((entry) {
                          return FilterChip(
                            selected: entry.value,
                            label: Text(entry.key.substring(0, 3)),
                            onSelected: _isEditMode
                                ? (selected) {
                                    setState(() {
                                      _workingDays[entry.key] = selected;
                                    });
                                  }
                                : null,
                            selectedColor: const Color(0xFF0B84FF),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: entry.value ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Working Hours
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeSelector(
                              "Start Time",
                              _startTime!,
                              () => _selectTime(true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeSelector(
                              "End Time",
                              _endTime!,
                              () => _selectTime(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Unavailable Dates
                      if (_unavailableDates.isNotEmpty) ...[
                        const Text(
                          "Unavailable Dates",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _unavailableDates.map((date) {
                            return Chip(
                              label: Text(DateFormat('MMM dd, yyyy').format(date)),
                              onDeleted: _isEditMode
                                  ? () => _removeUnavailableDate(date)
                                  : null,
                              deleteIcon: const Icon(Icons.close, size: 18),
                              backgroundColor: Colors.red.withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                if (_isEditMode)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B84FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _isEditMode
            ? TextField(
                controller: controller,
                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                maxLines: maxLines,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0B84FF), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.text.isEmpty
                      ? (label == "About" ? "No description provided." : "Not set")
                      : controller.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: _isEditMode ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isEditMode ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isEditMode ? const Color(0xFF0B84FF) : Colors.grey[300]!,
            width: _isEditMode ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: _isEditMode ? const Color(0xFF0B84FF) : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isEditMode ? const Color(0xFF0B84FF) : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
