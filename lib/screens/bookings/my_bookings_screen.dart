import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl to pubspec.yaml for date formatting
import '../../models/user_model.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // 1. STATE: Which filter is currently selected?
  String _selectedFilter = 'All';

  // 2. DUMMY DATA: Matching your screenshot
  final List<Booking> allBookings = [
    Booking(
      id: "BK001",
      providerName: "Juan Dela Cruz",
      providerImage: "https://i.pravatar.cc/150?img=11",
      serviceCategory: "Plumbing",
      status: "Accepted",
      date: DateTime(2024, 12, 10),
      time: "10:00 AM",
      address: "123 Mango St, Davao",
    ),
    Booking(
      id: "BK002",
      providerName: "Ana Rodriguez",
      providerImage: "https://i.pravatar.cc/150?img=5",
      serviceCategory: "Electrical",
      status: "Pending",
      date: DateTime(2024, 12, 12),
      time: "2:00 PM",
      address: "456 Calamansi Ave, Davao",
    ),
    Booking(
      id: "BK003",
      providerName: "Rosa Flores",
      providerImage: "https://i.pravatar.cc/150?img=9",
      serviceCategory: "Cleaning",
      status: "Declined",
      date: DateTime(2024, 12, 8),
      time: "9:00 AM",
      address: "789 Durian Blvd, Davao",
    ),
    Booking(
      id: "BK004",
      providerName: "Maria Garcia",
      providerImage: "https://i.pravatar.cc/150?img=20",
      serviceCategory: "Plumbing",
      status: "Accepted",
      date: DateTime(2024, 12, 15),
      time: "3:30 PM",
      address: "321 Banana Rd, Davao",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 3. LOGIC: Filter the list based on selection
    List<Booking> filteredList = _selectedFilter == 'All'
        ? allBookings
        : allBookings.where((b) => b.status == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: Colors.white, // Or Colors.grey[50]
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Bookings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage and track your service requests",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // --- FILTER TABS ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab("All", count: allBookings.length),
                  _buildFilterTab(
                    "Pending",
                    count: 1,
                  ), // logic to count real data can be added
                  _buildFilterTab("Accepted", count: 2),
                  _buildFilterTab("Declined", count: 1),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- BOOKING LIST ---
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  return _buildBookingCard(filteredList[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildFilterTab(String title, {required int count}) {
    final bool isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B84FF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "$title ($count)",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    // Determine status color
    Color statusColor;
    Color statusBgColor;

    switch (booking.status) {
      case 'Accepted':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case 'Pending':
        statusColor = const Color(0xFFFFC107); // Amber/Yellow
        statusBgColor = const Color(0xFFFFC107).withOpacity(0.1);
        break;
      case 'Declined':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  booking.providerImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, _) =>
                      Container(width: 60, height: 60, color: Colors.grey[300]),
                ),
              ),
              const SizedBox(width: 16),

              // Middle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          booking.providerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            booking.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.serviceCategory,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Date, Time, Location Row
                    _buildInfoRow(
                      Icons.calendar_today,
                      DateFormat('yyyy-MM-dd').format(booking.date),
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.access_time, booking.time),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.location_on_outlined, booking.address),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 8),

          // Bottom Row: ID and Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking ID",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Text(
                    booking.id,
                    style: const TextStyle(
                      color: Color(0xFF0B84FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showBookingDetails(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B84FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  "View Details",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    // Map status to colors reused across the sheet
    Color statusColor;
    Color statusBgColor;
    switch (booking.status) {
      case 'Accepted':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.12);
        break;
      case 'Pending':
        statusColor = const Color(0xFFFFC107);
        statusBgColor = const Color(0xFFFFC107).withOpacity(0.12);
        break;
      case 'Declined':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.12);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.12);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          booking.providerImage,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, _) => Container(
                            width: 72,
                            height: 72,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.providerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.serviceCategory,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                booking.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailTile(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Booking ID',
                    value: booking.id,
                    accentColor: const Color(0xFF0B84FF),
                  ),
                  _buildDetailTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: DateFormat('EEE, MMM d, y').format(booking.date),
                  ),
                  _buildDetailTile(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: booking.time,
                  ),
                  _buildDetailTile(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: booking.address,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Notes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add provider notes, access instructions, or attachments here once backend is connected.',
                    style: TextStyle(color: Colors.grey[700], height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Hook messaging/call action when backend is ready
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message Provider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B84FF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    Color accentColor = Colors.black54,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
