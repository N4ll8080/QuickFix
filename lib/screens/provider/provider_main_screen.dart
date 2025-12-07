import 'package:flutter/material.dart';
import 'provider_dashboard_screen.dart';
// You can create placeholders for these other screens later
// import 'provider_requests_screen.dart';
// import 'provider_profile_screen.dart';

class ProviderMainScreen extends StatefulWidget {
  const ProviderMainScreen({super.key});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _selectedIndex = 0;

  // Define the screens for each tab
  final List<Widget> _screens = [
    const ProviderDashboardScreen(), // The design from your image
    const Center(child: Text("Incoming Requests Screen")), // Placeholder
    const Center(child: Text("Booking History Screen")), // Placeholder
    const Center(child: Text("Profile Settings Screen")), // Placeholder
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF0B84FF), // QuickFix Blue
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_outlined),
              activeIcon: Icon(Icons.notifications_active),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
