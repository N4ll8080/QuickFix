import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool isAvailable = true;

  Future<void> _handleLogout() async {
    // Centralized logout: let AuthWrapper react to authStateChanges
    await AuthService().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        // Bind dashboard data to the live auth state so we don't keep
        // querying with a UID after sign-out or token expiry.
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authSnapshot.data;
          if (user == null) {
            return const Center(
              child: Text(
                'You are not logged in.\nPlease sign in again to view your dashboard.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final uid = user.uid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER (Profile Stream)
                StreamBuilder<UserModel?>(
                  stream: _dbService.getUserStream(uid),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        profile == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (profile == null) {
                      return const SizedBox(); // Gracefully handle missing profile
                    }

                    return _buildHeaderCard(profile);
                  },
                ),

                const SizedBox(height: 24),

                // 2. STATS (Booking Stream)
                StreamBuilder<List<Booking>>(
                  stream: _dbService.getProviderBookings(uid),
                  builder: (context, snapshot) {
                    final bookings = snapshot.data ?? [];

                    // Calculate Stats (statuses are normalized to lowercase in Booking.fromMap)
                    final pending = bookings
                        .where((b) => b.status == 'pending')
                        .length;
                    final accepted = bookings
                        .where((b) => b.status == 'accepted' || b.status == 'confirmed')
                        .length;

                    // Calculate Earnings (Sum of price for 'completed' jobs)
                    final earnings = bookings
                        .where((b) => b.status == 'completed')
                        .fold(0.0, (sum, b) => sum + b.price);

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          title: "Pending Requests",
                          value: "$pending",
                          color: Colors.orange,
                          bgColor: Colors.orange.withOpacity(0.1),
                        ),
                        _buildStatCard(
                          title: "Active Jobs",
                          value: "$accepted",
                          color: Colors.blue,
                          bgColor: Colors.blue.withOpacity(0.1),
                        ),
                        _buildStatCard(
                          title: "Total Bookings",
                          value: "${bookings.length}",
                          color: Colors.green,
                          bgColor: Colors.green.withOpacity(0.1),
                        ),
                        _buildEarningsCard(earnings),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF0B84FF),
            backgroundImage: user.imageUrl != null
                ? NetworkImage(user.imageUrl!)
                : null,
            child: user.imageUrl == null
                ? Text(
                    user.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${user.category ?? 'Provider'} • ₱${user.rate?.toStringAsFixed(0)}/hr",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: user.isAvailable,
            activeColor: Colors.green,
            onChanged: (val) {
              // Optimistic update
              final updatedUser = UserModel(
                id: user.id,
                email: user.email,
                name: user.name,
                phone: user.phone,
                userType: user.userType,
                category: user.category,
                rate: user.rate,
                about: user.about,
                imageUrl: user.imageUrl,
                rating: user.rating,
                reviewCount: user.reviewCount,
                isAvailable: val, // <--- Toggle
              );
              _dbService.updateUserProfile(updatedUser);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Total Earnings",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            "₱${amount.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
