import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import 'booking_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  int _tabIndex = 0; // 0: upcoming, 1: pending, 2: history

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
      case 'in progress':
      case 'rescheduled':
        return Colors.green;
      case 'pending':
      case 'requested':
      case 'booked':
        return const Color(0xFFFFC107);
      case 'cancelled':
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B84FF)),
              ),
            );
          }

          final user = authSnapshot.data;
          if (user == null) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You are not logged in.\nPlease sign in to view your bookings.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final currentUserId = user.uid;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0B84FF),
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text(
                    'My Bookings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),

              // Filter Tabs and History Toggle
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          _buildTab('Upcoming', 0),
                          _buildTab('Pending', 1),
                          _buildTab('History', 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Booking List Stream
              StreamBuilder<List<Booking>>(
                stream: _dbService.getSeekerBookings(currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0B84FF),
                          ),
                        ),
                      ),
                    );
                  }

                  final allBookings = snapshot.data ?? [];
                  final upcomingStatuses = {
                    'accepted',
                    'confirmed',
                    'in progress',
                    'rescheduled',
                  };
                  final pendingStatuses = {'pending', 'requested', 'booked'};
                  final historyStatuses = {
                    'completed',
                    'cancelled',
                    'declined',
                  };

                  final upcomingBookings = allBookings
                      .where((b) => upcomingStatuses.contains(b.status))
                      .toList();
                  final pendingBookings = allBookings
                      .where((b) => pendingStatuses.contains(b.status))
                      .toList();
                  final historyBookings = allBookings
                      .where((b) => historyStatuses.contains(b.status))
                      .toList();

                  List<Booking> filteredList;
                  if (_tabIndex == 0) {
                    filteredList = upcomingBookings;
                  } else if (_tabIndex == 1) {
                    filteredList = pendingBookings;
                  } else {
                    filteredList = historyBookings;
                  }

                  if (filteredList.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No bookings found",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _buildBookingCard(filteredList[index]);
                      }, childCount: filteredList.length),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 6,
            right: index == 2 ? 0 : 6,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B84FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0B84FF)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF0B84FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BookingDetailsScreen(booking: booking, isProvider: false),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
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
                Expanded(
                  child: Text(
                    booking.providerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B84FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.serviceCategory,
                style: const TextStyle(
                  color: Color(0xFF0B84FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              DateFormat('MMMM dd, yyyy').format(booking.date),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, booking.time),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, booking.address),
            if (booking.problemDescription.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.problemDescription,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0B84FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF0B84FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
