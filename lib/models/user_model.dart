// lib/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String userType; // 'seeker' or 'provider'

  // Provider specific fields
  final String? category;
  final double? rate;
  final String? about;
  final String? imageUrl;
  final double rating; // Added for UI display
  final int reviewCount; // Added for UI display
  final bool isAvailable; // Added for UI display
  final Map<String, dynamic>? availability; // Working days, times, unavailable dates

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    this.category,
    this.rate,
    this.about,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
    this.availability,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      userType: map['userType'] ?? 'seeker',
      category: map['category'],
      rate: map['rate'] != null
          ? double.tryParse(map['rate'].toString())
          : null,
      about: map['about'],
      imageUrl: map['imageUrl'],
      rating: map['rating'] != null
          ? double.tryParse(map['rating'].toString()) ?? 0.0
          : 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      availability: map['availability'] != null
          ? Map<String, dynamic>.from(map['availability'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType,
      if (category != null) 'category': category,
      if (rate != null) 'rate': rate,
      if (about != null) 'about': about,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      if (availability != null) 'availability': availability,
    };
  }
}

class Booking {
  final String id;
  final String seekerId;
  final String providerId;
  final String providerName;
  final String serviceCategory;
  final String status;
  final DateTime date;
  final String time;
  final String address;
  final String problemDescription;
  final double price; // <--- NEW FIELD

  Booking({
    required this.id,
    required this.seekerId,
    required this.providerId,
    required this.providerName,
    required this.serviceCategory,
    required this.status,
    required this.date,
    required this.time,
    required this.address,
    required this.problemDescription,
    required this.price, // <--- Add to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'seekerId': seekerId,
      'providerId': providerId,
      'providerName': providerName,
      'serviceCategory': serviceCategory,
      'status': status,
      'date': date.toIso8601String(),
      'time': time,
      'address': address,
      'problemDescription': problemDescription,
      'price': price, // <--- Add to map
    };
  }

  factory Booking.fromMap(Map<dynamic, dynamic> map, String id) {
    return Booking(
      id: id,
      seekerId: map['seekerId'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      serviceCategory: map['serviceCategory'] ?? '',
      status: map['status'] ?? 'Pending',
      date: DateTime.parse(map['date']),
      time: map['time'] ?? '',
      address: map['address'] ?? '',
      problemDescription: map['problemDescription'] ?? '',
      price: map['price'] != null
          ? double.tryParse(map['price'].toString()) ?? 0.0
          : 0.0, // <--- Add to factory
    );
  }
}
