import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../messages/chat_screen.dart';
import '../../services/messaging_service.dart';
import '../../services/auth_service.dart';
import '../bookings/create_booking_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  final UserModel provider;

  const ProviderProfileScreen({super.key, required this.provider});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _openChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final currentUserModel = await _authService.getUserProfile();
      if (currentUserModel == null) return;

      final chatId = await _messagingService.getOrCreateChat(
        currentUser.uid,
        widget.provider.id,
        currentUserModel.name,
        widget.provider.name,
        userImageUrl1: currentUserModel.imageUrl,
        userImageUrl2: widget.provider.imageUrl,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserId: widget.provider.id,
            otherUserName: widget.provider.name,
            otherUserImageUrl: widget.provider.imageUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  void _bookAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBookingScreen(provider: widget.provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Provider Details",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
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
                      // Profile Picture with Verified Badge
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            child: widget.provider.imageUrl != null &&
                                    widget.provider.imageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.provider.imageUrl!,
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
                            Text(
                              widget.provider.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.provider.category ?? "Service Provider",
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
                                    index < widget.provider.rating.floor()
                                        ? Icons.star
                                        : (index < widget.provider.rating
                                            ? Icons.star_half
                                            : Icons.star_border),
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  "${widget.provider.rating.toStringAsFixed(1)} (${widget.provider.reviewCount})",
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
                                color: widget.provider.isAvailable
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.provider.isAvailable ? "Available" : "Busy",
                                style: TextStyle(
                                  color: widget.provider.isAvailable
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

                // Details Card
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
                        "Service Information",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow(
                        "Hourly Rate",
                        "₱${widget.provider.rate?.toStringAsFixed(0) ?? '0'} /hr",
                        isHighlight: true,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        "Phone Number",
                        widget.provider.phone,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        "Email",
                        widget.provider.email,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        "About",
                        widget.provider.about?.isNotEmpty == true
                            ? widget.provider.about!
                            : "No description provided.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Services Offered Card
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
                        "Services Offered",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildServiceTag(widget.provider.category ?? "General Services"),
                          _buildServiceTag("Consultation"),
                          _buildServiceTag("Emergency Service"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      // Sticky Floating Buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Message Button
          FloatingActionButton.extended(
            onPressed: _openChat,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0B84FF),
            icon: const Icon(Icons.message),
            label: const Text(
              "Message Provider",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 4,
          ),
          const SizedBox(height: 12),
          // Book Appointment Button
          FloatingActionButton.extended(
            onPressed: _bookAppointment,
            backgroundColor: const Color(0xFF0B84FF),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.calendar_today),
            label: const Text(
              "Book Appointment",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? const Color(0xFF0B84FF) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTag(String service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B84FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0B84FF).withOpacity(0.3),
        ),
      ),
      child: Text(
        service,
        style: const TextStyle(
          color: Color(0xFF0B84FF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
