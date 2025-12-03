import 'package:flutter/material.dart';
import '../../models/user_model.dart'; // Import your Provider model

class ProviderProfileScreen extends StatelessWidget {
  final Provider provider;

  const ProviderProfileScreen({Key? key, required this.provider})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the color based on the category (e.g., your brand blue)
    final Color primaryColor = const Color(0xFF0B84FF);
    final Color availableColor = const Color(0xFF4CAF50); // Green

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Back to Providers',
          style: TextStyle(color: primaryColor, fontSize: 16),
        ),
        titleSpacing: 0, // Align title closer to the icon
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER / BANNER SECTION ---
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, const Color(0xFF1E6FFF)],
                ),
              ),
              child:
                  const SizedBox(), // Empty container for the blue background
            ),

            // --- PROFILE CARD & OVERVIEW ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image (positioned over the banner)
                  Transform.translate(
                    offset: const Offset(0, -60), // Move up by 60 units
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            image: DecorationImage(
                              image: NetworkImage(provider.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name and Profession
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  provider.category +
                                      ' Professional', // e.g., 'Plumbing Professional'
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rating and Verified Status (Adjusted position after image shift)
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount} reviews)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: availableColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: availableColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: availableColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- STATS BAR (Rate, Experience, Response Time) ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Use Wrap for smaller screens, Row for larger screens
                      if (constraints.maxWidth < 600) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildStatCard(
                              title: 'Status',
                              value: provider.isAvailable
                                  ? 'Available'
                                  : 'Busy',
                              color: provider.isAvailable
                                  ? availableColor
                                  : Colors.red,
                              isPill: true,
                              isExpanded: false,
                            ),
                            _buildStatCard(
                              title: 'Rate',
                              value:
                                  '₱${provider.pricePerHour.toStringAsFixed(0)}',
                              subtitle: '/hour',
                              isExpanded: false,
                            ),
                            _buildStatCard(
                              title: 'Experience',
                              value: '6+ years', // Dummy static value
                              icon: Icons.work,
                              isExpanded: false,
                            ),
                            _buildStatCard(
                              title: 'Response Time',
                              value: '< 1 hour', // Dummy static value
                              icon: Icons.timer,
                              isExpanded: false,
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Status',
                                value: provider.isAvailable
                                    ? 'Available'
                                    : 'Busy',
                                color: provider.isAvailable
                                    ? availableColor
                                    : Colors.red,
                                isPill: true,
                                isExpanded: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Rate',
                                value:
                                    '₱${provider.pricePerHour.toStringAsFixed(0)}',
                                subtitle: '/hour',
                                isExpanded: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Experience',
                                value: '6+ years', // Dummy static value
                                icon: Icons.work,
                                isExpanded: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Response Time',
                                value: '< 1 hour', // Dummy static value
                                icon: Icons.timer,
                                isExpanded: true,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30),

                  // --- ABOUT SECTION ---
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- CONTACT INFORMATION ---
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  _buildContactRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: provider.phoneNumber,
                  ),
                  const SizedBox(height: 8),
                  // Service Area
                  _buildContactRow(
                    icon: Icons.location_on_outlined,
                    label: 'Service Area',
                    value: provider.location + ' & nearby areas',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // --- ACTION BUTTONS (Stuck to bottom) ---
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.call, color: Color(0xFF0B84FF)),
                      label: const Text(
                        'Call Now',
                        style: TextStyle(color: Color(0xFF0B84FF)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF0B84FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.book_online, color: Colors.white),
                      label: const Text(
                        'Book Service',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: availableColor, // Green for booking
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  // Helper Widget for the Stat Cards (Rate, Experience, etc.)
  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    IconData? icon,
    Color? color,
    bool isPill = false,
    bool isExpanded = true,
  }) {
    Widget card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color != null && isPill
            ? color.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: color != null && isPill
            ? Border.all(color: color.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: Colors.black87),
              if (icon != null) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null)
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return isExpanded
        ? Expanded(child: card)
        : SizedBox(width: 120, child: card);
  }

  // Helper Widget for Contact Information Rows
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0B84FF), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
