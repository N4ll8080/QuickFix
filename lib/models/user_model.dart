import 'package:firebase_database/firebase_database.dart';

import '../core/safety_utils.dart';
import '../core/time_utils.dart';

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
  final Map<String, dynamic>?
  availability; // Working days, times, unavailable dates

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
      name: map['name'] ?? 'Unknown Provider',
      phone: map['phone'] ?? '',
      userType: map['userType'] ?? 'seeker',
      category: map['category'],
      rate: map['rate'] != null
          ? double.tryParse(map['rate'].toString())
          : null,
      about: map['about'],
      imageUrl: validatedUrl(map['imageUrl'] as String?) ?? kFallbackPhoto,
      rating: map['rating'] != null
          ? double.tryParse(map['rating'].toString()) ?? 0.0
          : 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      availability: _parseAvailability(map['availability']),
    );
  }

  static Map<String, dynamic>? _parseAvailability(dynamic raw) {
    if (raw == null) return null;
    
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    
    if (raw is Map) {
      try {
        return Map<String, dynamic>.from(raw);
      } catch (e) {
        print('Warning: Failed to parse availability map: $e');
        return null;
      }
    }
    
    // If it's a String or other type, log and return null
    print('Warning: Availability field is ${raw.runtimeType}, expected Map. Ignoring.');
    return null;
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
  final String bookingId;
  final String seekerId;
  final String seekerName;
  final String providerId;
  final String providerName;
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final String status;
  final DateTime date;
  final String time;
  final String address;
  final String notes;
  final String problemDescription;
  final double price; // stored as snapshot; derived from cents if present

  Booking({
    required this.id,
    required this.bookingId,
    required this.seekerId,
    required this.seekerName,
    required this.providerId,
    required this.providerName,
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    required this.status,
    required this.date,
    required this.time,
    required this.address,
    required this.notes,
    required this.problemDescription,
    required this.price, // <--- Add to constructor
  });

  Map<String, dynamic> toMap() {
    final slotDateKey = dateKeyUtc(date);
    final timeKey = normalizeTimeKey(time);
    final slotUtc = combineDateAndTimeUtc(date, time);
    return {
      'bookingId': bookingId,
      'seekerId': seekerId,
      'seekerName': seekerName,
      'providerId': providerId,
      'providerName': providerName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'scheduleDate': slotDateKey,
      'scheduleTime': time,
      'slotDate': slotDateKey,
      'slotTime': timeKey,
      'slotUtc': slotUtc.toIso8601String(),
      'status': status,
      'address': address,
      'notes': notes,
      'problemDescription': problemDescription,
      'priceCents': (price * 100).round(),
      'createdAt': ServerValue.timestamp,
    };
  }

  factory Booking.fromMap(Map<dynamic, dynamic> map, String id) {
    final rawTime = map['scheduleTime'] ?? map['slotTime'] ?? map['time'] ?? '';
    final displayTime = isTimeKey(rawTime.toString())
        ? displayTimeFromKey(rawTime.toString())
        : rawTime.toString();
    final slotIso = map['slotUtc'] ?? map['date'];
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(slotIso);
    } catch (_) {
      parsedDate = DateTime.now().toUtc();
    }
    final priceCents = map['priceCents'];
    final priceDouble = map['price'] != null
        ? double.tryParse(map['price'].toString())
        : null;
    final resolvedPrice = priceCents != null
        ? (int.tryParse(priceCents.toString()) ?? 0) / 100
        : (priceDouble ?? 0.0);
    return Booking(
      id: id,
      bookingId: map['bookingId'] ?? id,
      seekerId: map['seekerId'] ?? '',
      seekerName: map['seekerName'] ?? 'Customer',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? 'Unavailable Provider',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? map['serviceCategory'] ?? '',
      serviceCategory: map['serviceCategory'] ?? '',
      status: (map['status'] ?? 'pending').toString().toLowerCase(),
      date: parsedDate.toUtc(),
      time: displayTime,
      address: map['address'] ?? '',
      notes: map['notes'] ?? map['problemDescription'] ?? '',
      problemDescription: map['problemDescription'] ?? '',
      price: resolvedPrice,
    );
  }
}
