import 'package:flutter/material.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  // Dummy data matching your screenshot
  final List<ProviderBooking> bookings = [
    ProviderBooking(
      id: "1",
      customerName: "Maria Santos",
      customerPhone: "0920-111-2222",
      date: "Nov 28, 2025",
      time: "10:00 AM",
      location: "123 Mango St, Davao City",
      serviceNeeded: "Leaking pipe under kitchen sink",
      status: "Confirmed",
    ),
    ProviderBooking(
      id: "2",
      customerName: "Pedro Reyes",
      customerPhone: "0921-333-4444",
      date: "Nov 27, 2025",
      time: "2:00 PM",
      location: "456 Calamansi Ave, Davao City",
      serviceNeeded: "Bathroom faucet repair",
      status: "Completed",
    ),
    ProviderBooking(
      id: "3",
      customerName: "Angela Lopez",
      customerPhone: "0922-555-6666",
      date: "Nov 29, 2025",
      time: "9:00 AM",
      location: "789 Sampaguita Rd, Davao City",
      serviceNeeded: "Water heater installation",
      status: "Confirmed",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Bookings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(ProviderBooking booking) {
    final bool isCompleted = booking.status == "Completed";
    // Color coding: Blue for Confirmed/Active, Green for Completed
    final Color statusColor = isCompleted
        ? const Color(0xFF00C853) // Green
        : const Color(0xFF2979FF); // Blue
    final Color statusBgColor = isCompleted
        ? const Color(0xFFE8F5E9) // Light Green
        : const Color(0xFFE3F2FD); // Light Blue

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior:
          Clip.hardEdge, // Ensures the left border strip respects radius
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Colored Strip
            Container(width: 6, color: statusColor),
            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header: Name & Status Badge ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.customerPhone,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(
                                  0xFF0B84FF,
                                ), // Blue link color style
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            booking.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[100]),
                    const SizedBox(height: 16),

                    // --- Info Grid (Date/Time & Location) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildInfoItem(
                            Icons.access_time,
                            "Date & Time",
                            "${booking.date} at ${booking.time}",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: _buildInfoItem(
                            Icons.location_on_outlined,
                            "Location",
                            booking.location,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Service Needed ---
                    const Text(
                      "Service Needed",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.serviceNeeded,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),

                    // --- Action Button (Only if NOT completed) ---
                    if (!isCompleted) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Handle Mark as Completed
                          },
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            "Mark as Completed",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF00C853,
                            ), // Success Green
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Local model for this screen
class ProviderBooking {
  final String id;
  final String customerName;
  final String customerPhone;
  final String date;
  final String time;
  final String location;
  final String serviceNeeded;
  final String status; // "Confirmed" or "Completed"

  ProviderBooking({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    required this.time,
    required this.location,
    required this.serviceNeeded,
    required this.status,
  });
}
