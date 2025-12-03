// lib/models/user_model.dart

// ----------------------------------------------------
// 1. User Model (Your Existing Code)
// ----------------------------------------------------
class User {
  final String id;
  final String email;
  final String name;
  final String userType; // 'seeker' or 'provider'

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      userType: json['userType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'userType': userType};
  }
}

// ----------------------------------------------------
// 2. Provider Model (The New Code)
// ----------------------------------------------------
class Provider {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final double pricePerHour;
  final String phoneNumber;
  final String location;
  final String description;
  final List<String> tags;
  final String imageUrl;

  Provider({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.pricePerHour,
    required this.phoneNumber,
    required this.location,
    required this.description,
    required this.tags,
    required this.imageUrl,
  });

  // Optional: Add fromJson/toJson methods here if you fetch provider data separately
  // factory Provider.fromJson(Map<String, dynamic> json) { ... }
}
