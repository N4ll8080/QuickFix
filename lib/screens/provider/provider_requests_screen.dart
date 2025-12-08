import 'package:flutter/material.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  // Dummy data matching your screenshot
  final List<IncomingRequest> requests = [
    IncomingRequest(
      id: "1",
      customerName: "Maria Santos",
      customerPhone: "0920-111-2222",
      date: "Nov 28, 2025",
      time: "10:00 AM",
      locationShort: "123 Mango St, Davao City",
      problemDescription:
          "Leaking pipe under kitchen sink, needs urgent repair",
      fullAddress: "123 Mango St, Poblacion District, Davao City, 8000",
      status: "Pending",
    ),
    IncomingRequest(
      id: "2",
      customerName: "Pedro Reyes",
      customerPhone: "0921-333-4444",
      date: "Nov 28, 2025",
      time: "2:00 PM",
      locationShort: "456 Calamansi Ave, Davao City",
      problemDescription: "Bathroom faucet dripping constantly",
      fullAddress: "456 Calamansi Ave, Buhangin District, Davao City",
      status: "Pending",
    ),
    IncomingRequest(
      id: "3",
      customerName: "Angela Lopez",
      customerPhone: "0922-555-6666",
      date: "Nov 29, 2025",
      time: "9:00 AM",
      locationShort: "789 Sampaguita Rd, Davao City",
      problemDescription: "Outlet sparking when plugging in appliances",
      fullAddress: "789 Sampaguita Rd, Matina, Davao City",
      status: "Pending",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Matches your app theme
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Incoming Booking Requests",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index]);
        },
      ),
    );
  }

  Widget _buildRequestCard(IncomingRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Name, Phone, Status ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.customerPhone,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4), // Light Yellow
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status,
                  style: const TextStyle(
                    color: Color(0xFFFBC02D), // Darker Yellow text
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),

          // --- DATE / TIME / LOCATION ROW ---
          Row(
            children: [
              Expanded(
                child: _buildIconInfo(
                  Icons.calendar_today_outlined,
                  "Date",
                  request.date,
                ),
              ),
              Expanded(
                child: _buildIconInfo(Icons.access_time, "Time", request.time),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildIconInfo(
            Icons.location_on_outlined,
            "Location",
            request.locationShort,
          ),

          const SizedBox(height: 20),

          // --- PROBLEM DESCRIPTION ---
          const Text(
            "Problem Description",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            request.problemDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // --- FULL ADDRESS ---
          const Text(
            "Full Address",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            request.fullAddress,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          const SizedBox(height: 24),

          // --- ACTION BUTTONS ---
          Row(
            children: [
              // Accept Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle Accept Logic
                  },
                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                  label: const Text(
                    "Accept Request",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853), // Success Green
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Decline Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle Decline Logic
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFD32F2F),
                    size: 20,
                  ),
                  label: const Text(
                    "Decline",
                    style: TextStyle(
                      color: Color(0xFFD32F2F), // Red Text
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE), // Light Red Bg
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Model class specific to this screen
class IncomingRequest {
  final String id;
  final String customerName;
  final String customerPhone;
  final String date;
  final String time;
  final String locationShort;
  final String problemDescription;
  final String fullAddress;
  final String status;

  IncomingRequest({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    required this.time,
    required this.locationShort,
    required this.problemDescription,
    required this.fullAddress,
    required this.status,
  });
}
