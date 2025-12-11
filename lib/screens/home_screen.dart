import 'package:flutter/material.dart';
import '../screens/providers_list/providers_list_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late PageController _carouselController;
  int _currentCarouselIndex = 0;
  late AnimationController _carouselAnimationController;

  // Carousel slides with real image URLs
  final List<CarouselSlide> carouselSlides = [
    CarouselSlide(
      title: 'Expert Plumbing Services',
      subtitle: 'Fix leaks, install fixtures, and more',
      imageUrl:
          'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=800',
      category: 'Plumbing',
    ),
    CarouselSlide(
      title: 'Professional Electrical Work',
      subtitle: 'Safe and reliable electrical solutions',
      imageUrl:
          'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=800',
      category: 'Electrical',
    ),
    CarouselSlide(
      title: 'Spotless Home Cleaning',
      subtitle: 'Deep cleaning for your home',
      imageUrl:
          'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
      category: 'Home Cleaning',
    ),
    CarouselSlide(
      title: 'Appliance Repair Experts',
      subtitle: 'Get your appliances working like new',
      imageUrl:
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
      category: 'Appliance Repair',
    ),
  ];

  // Service categories with real content
  final List<ServiceCategory> services = [
    ServiceCategory(
      icon: Icons.plumbing,
      name: 'Plumbing',
      description: 'Leak repairs, installations, maintenance',
      providers: 24,
      color: const Color(0xFF0B84FF),
    ),
    ServiceCategory(
      icon: Icons.electric_bolt,
      name: 'Electrical',
      description: 'Wiring, repairs, installations',
      providers: 18,
      color: const Color(0xFF0B84FF),
    ),
    ServiceCategory(
      icon: Icons.cleaning_services,
      name: 'Home Cleaning',
      description: 'Deep cleaning, regular maintenance',
      providers: 42,
      color: const Color(0xFF0B84FF),
    ),
    ServiceCategory(
      icon: Icons.build,
      name: 'Appliance Repair',
      description: 'AC, refrigerator, washing machine',
      providers: 12,
      color: const Color(0xFF0B84FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
    _carouselAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Auto-rotate carousel
    _carouselAnimationController.addListener(() {
      if (_carouselAnimationController.isCompleted) {
        if (_currentCarouselIndex < carouselSlides.length - 1) {
          _currentCarouselIndex++;
        } else {
          _currentCarouselIndex = 0;
        }
        _carouselController.animateToPage(
          _currentCarouselIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _carouselAnimationController.reset();
      }
    });

    // Listen to page changes
    _carouselController.addListener(() {
      setState(() {
        _currentCarouselIndex = _carouselController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _carouselAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleProviderLogin() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final carouselHeight = (screenHeight * 0.35).clamp(280.0, 320.0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Animated Carousel Section
              SizedBox(
                height: carouselHeight,
                child: PageView.builder(
                  controller: _carouselController,
                  itemCount: carouselSlides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentCarouselIndex = index;
                    });
                    _carouselAnimationController.reset();
                  },
                  itemBuilder: (context, index) {
                    final slide = carouselSlides[index];
                    return _buildCarouselSlide(slide);
                  },
                ),
              ),

              // Carousel Indicators
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  carouselSlides.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentCarouselIndex == index
                          ? const Color(0xFF0B84FF)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                      const Icon(
                        Icons.search,
                        color: Color(0xFF0B84FF),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for a service…',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Service Categories Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    return _buildServiceCard(services[index]);
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Provider CTA Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(32),
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
                        'Are you a service provider?',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Join QuickFix and grow your business.',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleProviderLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B84FF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Login as Provider',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselSlide(CarouselSlide slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                slide.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF0B84FF),
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.white, size: 64),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF0B84FF),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            // Dark Blue Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1E3A5F).withOpacity(0.7),
                      const Color(0xFF1E3A5F).withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProviderListScreen(categoryName: slide.category),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B84FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
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

  Widget _buildServiceCard(ServiceCategory service) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProviderListScreen(categoryName: service.name),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: service.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(service.icon, size: 40, color: service.color),
            ),
            const SizedBox(height: 12),
            Text(
              service.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              service.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${service.providers} Providers',
              style: TextStyle(
                color: service.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CarouselSlide {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String category;

  CarouselSlide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.category,
  });
}

class ServiceCategory {
  final IconData icon;
  final String name;
  final String description;
  final int providers;
  final Color color;

  ServiceCategory({
    required this.icon,
    required this.name,
    required this.description,
    required this.providers,
    required this.color,
  });
}
