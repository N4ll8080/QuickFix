import 'package:flutter/material.dart';
import '../screens/providers_list/providers_list_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Hardcoded categories for the UI tiles
  final List<ServiceCategory> services = [
    ServiceCategory(
      icon: Icons.plumbing,
      name: 'Plumbing',
      providers: 24, // Static number for UI display
      color: const Color(0xFF2196F3),
    ),
    ServiceCategory(
      icon: Icons.electric_bolt,
      name: 'Electrical',
      providers: 18,
      color: const Color(0xFFFFC107),
    ),
    ServiceCategory(
      icon: Icons.cleaning_services,
      name: 'Home Cleaning',
      providers: 42,
      color: const Color(0xFF8B4513),
    ),
    ServiceCategory(
      icon: Icons.build,
      name: 'Appliance Repair',
      providers: 12,
      color: Colors.grey,
    ),
  ];

  // Logic for the bottom "Provider Login" button
  Future<void> _handleProviderLogin() async {
    // Log out the current user (Seeker)
    await AuthService().logout();

    if (!mounted) return;

    // Redirect to Login Screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0B84FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.build_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'QuickFix',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B84FF), Color(0xFF1E6FFF)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 60, 40, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find Trusted Professionals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quick, reliable, and affordable services at your doorstep.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Visual-only Search Bar (Functional search is in ProviderListScreen)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        enabled:
                            false, // Disabled for now, or redirect to a search page
                        decoration: InputDecoration(
                          hintText: 'Select a category below to search',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Popular Services Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return ServiceCard(service: services[index]);
                },
              ),
            ),

            // Provider CTA Section
            Container(
              margin: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you a service provider?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Join QuickFix and grow your business.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleProviderLogin, // <--- Linked here
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Login as Provider'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCategory {
  final IconData icon;
  final String name;
  final int providers;
  final Color color;

  ServiceCategory({
    required this.icon,
    required this.name,
    required this.providers,
    required this.color,
  });
}

class ServiceCard extends StatelessWidget {
  final ServiceCategory service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProviderListScreen(categoryName: service.name),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(service.icon, size: 40, color: service.color),
            const SizedBox(height: 12),
            Text(
              service.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Text(
              '${service.providers} Providers',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
