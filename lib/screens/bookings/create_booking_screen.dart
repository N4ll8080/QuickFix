import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../core/safety_utils.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final UserModel provider;

  const CreateBookingScreen({super.key, required this.provider});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _problemController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedTime;
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  List<Booking> _existingBookings = [];
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    _loadExistingBookings();
  }

  Future<void> _loadExistingBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      final bookings = await _dbService
          .getProviderBookings(widget.provider.id)
          .first;
      setState(() {
        _existingBookings = bookings;
        _isLoadingBookings = false;
      });
    } catch (e) {
      setState(() => _isLoadingBookings = false);
    }
  }

  List<String> _generateTimeSlots() {
    final availability = widget.provider.availability;
    if (availability == null) {
      // Default slots if no availability set
      return [
        '8:00 AM',
        '9:00 AM',
        '10:00 AM',
        '11:00 AM',
        '12:00 PM',
        '1:00 PM',
        '2:00 PM',
        '3:00 PM',
        '4:00 PM',
        '5:00 PM',
      ];
    }

    final startTimeStr = availability['startTime'] ?? '9:00';
    final endTimeStr = availability['endTime'] ?? '17:00';

    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');

    final startHour = int.parse(startParts[0]);
    final startMinute = startParts.length > 1 ? int.parse(startParts[1]) : 0;
    final endHour = int.parse(endParts[0]);
    final endMinute = endParts.length > 1 ? int.parse(endParts[1]) : 0;

    final slots = <String>[];
    var currentHour = startHour;
    var currentMinute = startMinute;

    while (currentHour < endHour ||
        (currentHour == endHour && currentMinute < endMinute)) {
      final time = TimeOfDay(hour: currentHour, minute: currentMinute);
      slots.add(
        time.format(context),
      ); // keeps UI locale (12h); normalized on save

      currentMinute += 60; // Add 1 hour
      if (currentMinute >= 60) {
        currentMinute = 0;
        currentHour++;
      }
    }

    return slots;
  }

  bool _isSlotAvailable(String timeSlot) {
    if (_selectedDate == null) return true;

    // Check if date is unavailable
    final availability = widget.provider.availability;
    if (availability != null && availability['unavailableDates'] != null) {
      try {
        final unavailableDatesList = availability['unavailableDates'];
        if (unavailableDatesList is List) {
          final unavailableDates = unavailableDatesList
              .map((d) => DateTime.parse(d.toString()))
              .toList();

      final selectedDateOnly = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

          for (final unavailableDate in unavailableDates) {
            final unavailableDateOnly = DateTime(
              unavailableDate.year,
              unavailableDate.month,
              unavailableDate.day,
            );
            if (selectedDateOnly == unavailableDateOnly) {
              return false;
            }
          }
        }
      } catch (e) {
        print('Warning: Failed to parse unavailableDates: $e');
      }
    }

    // Check if day is a working day
    if (availability != null && availability['workingDays'] != null) {
      try {
        final workingDaysRaw = availability['workingDays'];
        if (workingDaysRaw != null) {
          final workingDays = Map<String, bool>.from(workingDaysRaw as Map);
          final dayName = DateFormat('EEEE').format(_selectedDate!);
          if (workingDays[dayName] != true) {
            return false;
          }
        }
      } catch (e) {
        print('Warning: Failed to parse workingDays: $e');
      }
    }

    // Check if slot is already booked
    final selectedDateOnly = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    for (final booking in _existingBookings) {
      final bookingDate = booking.date.toLocal();
      final bookingDateOnly = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
      );

      if (selectedDateOnly == bookingDateOnly &&
          booking.time == timeSlot &&
          booking.status != 'Cancelled' &&
          booking.status != 'Declined') {
        return false;
      }
    }

    return true;
  }

  String? _getSlotTooltip(String timeSlot) {
    if (_selectedDate == null) return null;

    if (!_isSlotAvailable(timeSlot)) {
      // Check why it's unavailable
      final availability = widget.provider.availability;

      // Check if date is unavailable
      if (availability != null && availability['unavailableDates'] != null) {
        try {
          final unavailableDatesList = availability['unavailableDates'];
          if (unavailableDatesList is List) {
            final unavailableDates = unavailableDatesList
                .map((d) => DateTime.parse(d.toString()))
                .toList();

        final selectedDateOnly = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );

            for (final unavailableDate in unavailableDates) {
              final unavailableDateOnly = DateTime(
                unavailableDate.year,
                unavailableDate.month,
                unavailableDate.day,
              );
              if (selectedDateOnly == unavailableDateOnly) {
                return 'Not Available';
              }
            }
          }
        } catch (e) {
          print('Warning: Failed to parse unavailableDates in tooltip: $e');
        }
      }

      // Check if day is not a working day
      if (availability != null && availability['workingDays'] != null) {
        try {
          final workingDaysRaw = availability['workingDays'];
          if (workingDaysRaw != null) {
            final workingDays = Map<String, bool>.from(workingDaysRaw as Map);
            final dayName = DateFormat('EEEE').format(_selectedDate!);
            if (workingDays[dayName] != true) {
              return 'Not Available';
            }
          }
        } catch (e) {
          print('Warning: Failed to parse workingDays in tooltip: $e');
        }
      }

      // Check if already booked
      final selectedDateOnly = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

      for (final booking in _existingBookings) {
        final bookingDateOnly = DateTime(
          booking.date.year,
          booking.date.month,
          booking.date.day,
        );

        if (selectedDateOnly == bookingDateOnly &&
            booking.time == timeSlot &&
            booking.status != 'Cancelled' &&
            booking.status != 'Declined') {
          return 'Already Booked';
        }
      }
    }

    return null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
      });
      await _loadExistingBookings(); // Reload bookings for new date
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    // Validate slot availability
    if (!_isSlotAvailable(_selectedTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This time slot is not available. Please select another time.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserModel = await _authService.getUserProfile();
    if (currentUserModel == null) return;

    try {
      final booking = Booking(
        id: '',
        bookingId: '',
        seekerId: currentUser.uid,
        seekerName: currentUserModel.name,
        providerId: widget.provider.id,
        providerName: widget.provider.name,
        serviceId: widget.provider.category ?? 'general',
        serviceName: widget.provider.category ?? 'General Service',
        serviceCategory: widget.provider.category ?? 'General',
        status: 'pending',
        date: _selectedDate!,
        time: _selectedTime!,
        address: _addressController.text.trim(),
        notes: _problemController.text.trim(),
        problemDescription: _problemController.text.trim(),
        price: widget.provider.rate ?? 0.0,
      );

      await _dbService.createBooking(booking);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateTimeSlots();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B84FF),
        elevation: 0,
        title: const Text(
          'Book Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      child:
                          widget.provider.imageUrl != null &&
                              widget.provider.imageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                safePhotoUrl(widget.provider.imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, size: 30);
                                },
                              ),
                            )
                          : const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.provider.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.provider.category ?? 'Service Provider',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${widget.provider.rate?.toStringAsFixed(0) ?? '0'}/hr',
                            style: const TextStyle(
                              color: Color(0xFF0B84FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Date Selection
              const Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0B84FF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Select a date'
                            : DateFormat(
                                'MMMM dd, yyyy',
                              ).format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Time Selection
              if (_selectedDate != null) ...[
                const Text(
                  'Select Time Slot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingBookings)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: timeSlots.map((time) {
                      final isSelected = _selectedTime == time;
                      final isAvailable = _isSlotAvailable(time);
                      final tooltip = _getSlotTooltip(time);

                      return Tooltip(
                        message:
                            tooltip ??
                            (isAvailable ? 'Available' : 'Not Available'),
                        child: InkWell(
                          onTap: isAvailable
                              ? () {
                                  setState(() => _selectedTime = time);
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        tooltip ?? 'This time is not available',
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0B84FF)
                                  : (isAvailable
                                        ? Colors.white
                                        : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0B84FF)
                                    : (isAvailable
                                          ? Colors.grey[300]!
                                          : Colors.red[300]!),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isAvailable
                                          ? Colors.black87
                                          : Colors.grey[600]),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                decoration: isAvailable
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
              ],

              // Address Field
              const Text(
                'Service Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Enter your address',
                  filled: true,
                  fillColor: Colors.white,
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
                    borderSide: const BorderSide(
                      color: Color(0xFF0B84FF),
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Problem Description Field
              const Text(
                'Problem Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _problemController,
                decoration: InputDecoration(
                  hintText: 'Describe the problem or service needed',
                  filled: true,
                  fillColor: Colors.white,
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
                    borderSide: const BorderSide(
                      color: Color(0xFF0B84FF),
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the problem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B84FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
