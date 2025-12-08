import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../screens/bookings/my_bookings_screen.dart';
import '../screens/profile/service_seeker_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1. Keep track of which tab is active
  int _selectedIndex = 0;

  // 2. Define the screens that correspond to each tab
  final List<Widget> _screens = [
    const HomeScreen(), // Index 0
    const MyBookingsScreen(), // Index 1
    const ServiceSeekerProfileScreen(), // Index 2 (Placeholder)
  ];

  // 3. Handle tab taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 4. The body switches based on the index
      body: _screens[_selectedIndex],

      // 5. The Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
          type: BottomNavigationBarType
              .fixed, // Use 'fixed' if you have 3-4 items
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF0B84FF), // Your Brand Blue
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          elevation: 0, // We added our own custom shadow above
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'My Bookings',
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
