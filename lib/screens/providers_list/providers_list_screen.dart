import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'provider_profile_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String categoryName;

  const ProviderListScreen({super.key, required this.categoryName});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  // --- DUMMY DATA (Matches your screenshot) ---
  final List<Provider> allProviders = [
    Provider(
      id: "1",
      name: "Juan Dela Cruz",
      category: "Plumbing",
      rating: 4.5,
      reviewCount: 127,
      isAvailable: true,
      pricePerHour: 500,
      phoneNumber: "0917-123-4567",
      location: "Davao City",
      description:
          "Licensed plumber with 10 years of experience. Specializing in residential and commercial plumbing solutions. Available for emergency repairs.",
      tags: ["Pipe Installation", "Leak Repair", "Water Heater"],
      imageUrl: "https://i.pravatar.cc/300?img=11", // Random man image
    ),
    Provider(
      id: "2",
      name: "Roberto Lim",
      category: "Plumbing",
      rating: 4.8,
      reviewCount: 89,
      isAvailable: false,
      pricePerHour: 450,
      phoneNumber: "0918-555-0199",
      location: "Davao City",
      description:
          "Expert in drainage systems and faucet repairs. Quick and reliable service.",
      tags: ["Drainage", "Faucets", "Maintenance"],
      imageUrl: "https://i.pravatar.cc/300?img=33", // Random man image
    ),
    // Add an electrician to test filtering
    Provider(
      id: "3",
      name: "Sarah Spark",
      category: "Electrical",
      rating: 5.0,
      reviewCount: 40,
      isAvailable: true,
      pricePerHour: 600,
      phoneNumber: "0920-111-2222",
      location: "Manila",
      description: "Certified electrician for home wiring.",
      tags: ["Wiring", "Lighting"],
      imageUrl: "https://i.pravatar.cc/300?img=5",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter the list based on the category passed from Home Screen
    final filteredProviders = allProviders
        .where((p) => p.category == widget.categoryName)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black), // Filter icon
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Search providers...",
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Results Count
              Text(
                "${filteredProviders.length} providers found",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // 3. The List of Cards
              ListView.builder(
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling inside scrollview
                shrinkWrap: true,
                itemCount: filteredProviders.length,
                itemBuilder: (context, index) {
                  return _buildProviderCard(filteredProviders[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET FOR THE CARD ---
  Widget _buildProviderCard(Provider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image + Name/Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    provider.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "${provider.rating}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            " (${provider.reviewCount})",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Availability Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: provider.isAvailable
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: provider.isAvailable
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: provider.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              provider.isAvailable ? "Available" : "Busy",
                              style: TextStyle(
                                color: provider.isAvailable
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
            const SizedBox(height: 16),

            // Price and Phone Row
            Row(
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "₱${provider.pricePerHour.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Color(0xFF0B84FF), // Your blue brand color
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        " /hour",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.phone, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    provider.phoneNumber,
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    provider.location,
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              provider.description,
              style: TextStyle(color: Colors.grey[800], height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Tags (Chips)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: Colors.grey[800], fontSize: 12),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Buttons (View Profile & Book Now)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // --- NEW NAVIGATION LOGIC ---
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProviderProfileScreen(provider: provider),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "View Profile",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B84FF), // Brand Blue
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Book Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
