// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../screens/providers_list/providers_list_screen.dart'; // Adjust path as necessary
// import '../../services/auth_service.dart';
// import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  final List<ServiceCategory> services = [
    ServiceCategory(
      icon: Icons.plumbing,
      name: 'Plumbing',
      providers: 24,
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
      name: 'Cleaning',
      providers: 42,
      color: const Color(0xFF8B4513),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Home',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'My Bookings',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Profile',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF0B84FF), const Color(0xFF1E6FFF)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 60, 40, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Find Trusted Professionals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quick, reliable, and affordable services at your doorstep. Browse top-rated\nproviders in your area.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 16,
                        height: 1.6,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 40),
                    // Search Bar
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'What service do you need?',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.black.withOpacity(0.4),
                            size: 24,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
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
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Popular Services',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a service category to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Services Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 1200
                          ? 4
                          : constraints.maxWidth > 800
                          ? 3
                          : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          return ServiceCard(service: services[index]);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 80),

                  // Why Choose QuickFix Section
                  const Text(
                    'Why Choose QuickFix?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        // Stack vertically on smaller screens
                        return Column(
                          children: [
                            _buildFeatureCard(
                              icon: Icons.flash_on,
                              iconColor: const Color(0xFFFFC107),
                              title: 'Quick Booking',
                              description:
                                  'Book services in minutes, get responses in hours',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureCard(
                              icon: Icons.verified_user,
                              iconColor: const Color(0xFF4CAF50),
                              title: 'Trusted Providers',
                              description:
                                  'Connect with verified local professionals',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureCard(
                              icon: Icons.attach_money,
                              iconColor: const Color(0xFFFF9800),
                              title: 'Best Prices',
                              description:
                                  'Compare rates and find affordable services',
                            ),
                          ],
                        );
                      } else {
                        // Row layout for larger screens
                        return Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.flash_on,
                                iconColor: const Color(0xFFFFC107),
                                title: 'Quick Booking',
                                description:
                                    'Book services in minutes, get responses in hours',
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.verified_user,
                                iconColor: const Color(0xFF4CAF50),
                                title: 'Trusted Providers',
                                description:
                                    'Connect with verified local professionals',
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.attach_money,
                                iconColor: const Color(0xFFFF9800),
                                title: 'Best Prices',
                                description:
                                    'Compare rates and find affordable services',
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 60),

                  // Provider CTA Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0B84FF),
                          const Color(0xFF1E6FFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Are you a service provider?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Join QuickFix and grow your business. Get more bookings, reach more customers.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0B84FF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Provider Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
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

class ServiceCard extends StatefulWidget {
  final ServiceCategory service;

  const ServiceCard({super.key, required this.service});

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          // Navigate to the generic screen, passing the specific data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderListScreen(
                categoryName:
                    widget.service.name, // Passes "Plumbing" or "Electrical"
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.service.color : Colors.grey.shade200,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.service.color.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: widget.service.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.service.icon,
                    color: widget.service.color,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                // Service Name
                Text(
                  widget.service.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Provider Count
                Text(
                  '${widget.service.providers} providers',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
