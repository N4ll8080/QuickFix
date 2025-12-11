import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../services/messaging_service_firestore.dart';
import '../../services/auth_service.dart';
import '../messages/chat_screen.dart';
import '../bookings/booking_details_screen.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final MessagingServiceFirestore _messagingService =
      MessagingServiceFirestore();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Handle Accept/Decline
  Future<void> _updateStatus(String bookingId, String status) async {
    try {
      await _dbService.updateBookingStatus(bookingId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Request $status"),
            backgroundColor: status.toLowerCase() == 'accepted'
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openChat(
    String seekerId,
    String seekerName,
    String? seekerImageUrl,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final currentUserModel = await _authService.getUserProfile();
      if (currentUserModel == null) return;

      final chatId = await _messagingService.getOrCreateChat(
        currentUser.uid,
        seekerId,
        currentUserModel.name,
        seekerName,
        userImageUrl1: currentUserModel.imageUrl,
        userImageUrl2: seekerImageUrl,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserId: seekerId,
            otherUserName: seekerName,
            otherUserImageUrl: seekerImageUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B84FF),
        elevation: 0,
        title: const Text(
          "Incoming Requests",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
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
                  'You are not logged in.\nPlease sign in to view incoming requests.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final currentUserId = user.uid;

          return StreamBuilder<List<Booking>>(
            stream: _dbService.getProviderBookings(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0B84FF),
                    ),
                  ),
                );
              }

              // Filter only 'Pending' or 'Requested' requests (case-insensitive)
              final requests = (snapshot.data ?? [])
                  .where(
                    (b) => ['pending', 'requested'].contains(b.status.toLowerCase()),
                  )
                  .toList();

              if (requests.isEmpty) {
                return Center(
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
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No pending requests",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return _buildRequestCard(requests[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Booking request) {
    return Container(
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "New Booking Request",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  request.status,
                  style: const TextStyle(
                    color: Color(0xFFFFC107),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Service Category
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B84FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.category, color: Color(0xFF0B84FF), size: 20),
                const SizedBox(width: 8),
                Text(
                  request.serviceCategory,
                  style: const TextStyle(
                    color: Color(0xFF0B84FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details
          _buildIconInfo(
            Icons.calendar_today,
            "Date",
            DateFormat('MMMM dd, yyyy').format(request.date),
          ),
          const SizedBox(height: 12),
          _buildIconInfo(Icons.access_time, "Time", request.time),
          const SizedBox(height: 12),
          _buildIconInfo(Icons.location_on, "Location", request.address),
          const SizedBox(height: 16),

          // Problem Description
          const Text(
            "Problem Description:",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              request.problemDescription,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingDetailsScreen(
                          booking: request,
                          isProvider: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text("View Details"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0B84FF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openChat(request.seekerId, 'Customer', null),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text("Message"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0B84FF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(request.id, "accepted"),
                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                  label: const Text(
                    "Accept",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(request.id, "declined"),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  label: const Text(
                    "Decline",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B84FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF0B84FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
