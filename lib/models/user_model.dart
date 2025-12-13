import 'dart:convert';
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
    
    Map<String, dynamic> parsedMap;
    
    // Handle Map types
    if (raw is Map<String, dynamic>) {
      parsedMap = Map<String, dynamic>.from(raw);
    } else if (raw is Map) {
      try {
        parsedMap = Map<String, dynamic>.from(raw);
      } catch (e) {
        print('Warning: Failed to parse availability map: $e');
        return null;
      }
    } else if (raw is String) {
      // Handle JSON string format (legacy data)
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          parsedMap = Map<String, dynamic>.from(decoded);
        } else {
          print('Warning: Availability JSON string decoded to non-Map type: ${decoded.runtimeType}');
          return null;
        }
      } catch (e) {
        print('Warning: Failed to parse availability JSON string: $e');
        return null;
      }
    } else {
      // If it's another type, log and return null
      print('Warning: Availability field is ${raw.runtimeType}, expected Map or JSON string. Ignoring.');
      return null;
    }
    
    // Recursively normalize nested fields like workingDays
    return _normalizeAvailabilityFields(parsedMap);
  }

  /// Recursively normalizes nested fields in availability data.
  /// Handles cases where nested fields like workingDays might be stored as JSON strings.
  static Map<String, dynamic> _normalizeAvailabilityFields(Map<String, dynamic> availability) {
    final normalized = <String, dynamic>{};
    
    for (final entry in availability.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Special handling for workingDays - it should be a Map<String, bool>
      if (key == 'workingDays') {
        normalized[key] = _parseWorkingDays(value);
      } else if (key == 'unavailableDates') {
        // Ensure unavailableDates is a List
        normalized[key] = _parseUnavailableDates(value);
      } else {
        // For other fields, preserve as-is or normalize if needed
        normalized[key] = value;
      }
    }
    
    return normalized;
  }

  /// Safely parses workingDays from Map, JSON string, or other formats.
  /// Returns a Map<String, bool> or null if parsing fails.
  static Map<String, bool>? _parseWorkingDays(dynamic raw) {
    if (raw == null) return null;
    
    // If it's already a Map, try to convert to Map<String, bool>
    if (raw is Map) {
      try {
        final result = <String, bool>{};
        raw.forEach((key, value) {
          final stringKey = key.toString();
          // Convert value to bool (handle true/false, "true"/"false", 1/0, etc.)
          if (value is bool) {
            result[stringKey] = value;
          } else if (value is String) {
            result[stringKey] = value.toLowerCase() == 'true' || value == '1';
          } else if (value is int) {
            result[stringKey] = value != 0;
          } else {
            result[stringKey] = false;
          }
        });
        return result;
      } catch (e) {
        print('Warning: Failed to parse workingDays map: $e');
        return null;
      }
    }
    
    // If it's a JSON string, try to decode it
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return _parseWorkingDays(decoded); // Recursively parse the decoded map
        } else {
          print('Warning: workingDays JSON string decoded to non-Map type: ${decoded.runtimeType}');
          return null;
        }
      } catch (e) {
        print('Warning: Failed to parse workingDays JSON string: $e');
        return null;
      }
    }
    
    print('Warning: workingDays is ${raw.runtimeType}, expected Map or JSON string. Ignoring.');
    return null;
  }

  /// Safely parses unavailableDates from List or other formats.
  static List<dynamic>? _parseUnavailableDates(dynamic raw) {
    if (raw == null) return null;
    
    if (raw is List) {
      return List.from(raw);
    }
    
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return List.from(decoded);
        }
      } catch (e) {
        print('Warning: Failed to parse unavailableDates JSON string: $e');
      }
    }
    
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
