import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import 'booking_service.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://quick-fix-89d7f-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  BookingService get _bookingService => BookingService(_db);

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  // 1. Get Providers by Category
  Stream<List<UserModel>> getProvidersByCategory(String category) {
    return _db
        .ref('users')
        // Use orderByChild and equalTo to filter on the server side (REQUIRED INDEX!)
        .orderByChild('category')
        .equalTo(category)
        .onValue
        .map((event) {
          final List<UserModel> providers = [];
          if (event.snapshot.value != null) {
            final users = _asMap(event.snapshot.value);

            users.forEach((key, value) {
              final user = UserModel.fromMap(value, key);
              // Only check userType here, the category is already filtered by the query
              if (user.userType == 'provider') {
                providers.add(user);
              }
            });
          }
          return providers;
        });
  }

  // 2. Create a Booking with slot lock + price snapshot
  Future<void> createBooking(Booking booking) async {
    final priceCents = (booking.price * 100).round();
    await _bookingService.bookSlot(booking: booking, priceCents: priceCents);
  }

  // 3. Get Bookings for a specific Provider
  Stream<List<Booking>> getProviderBookings(String providerId) {
    return _db
        .ref('bookings')
        .orderByChild('providerId')
        .equalTo(providerId)
        .onValue
        .map((event) {
          final List<Booking> bookings = [];
          if (event.snapshot.value != null) {
            final data = _asMap(event.snapshot.value);
            data.forEach((key, value) {
              bookings.add(Booking.fromMap(value, key));
            });
          }
          // Sort by date descending
          bookings.sort((a, b) => b.date.compareTo(a.date));
          return bookings;
        });
  }

  // 4. Get Bookings for a specific Seeker
  Stream<List<Booking>> getSeekerBookings(String seekerId) {
    return _db
        .ref('bookings')
        .orderByChild('seekerId')
        .equalTo(seekerId)
        .onValue
        .map((event) {
          final List<Booking> bookings = [];
          if (event.snapshot.value != null) {
            final data = _asMap(event.snapshot.value);
            data.forEach((key, value) {
              bookings.add(Booking.fromMap(value, key));
            });
          }
          bookings.sort((a, b) => b.date.compareTo(a.date));
          return bookings;
        });
  }

  // 5. Update Booking Status
  // Normalizes status to lowercase for consistency
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final normalizedStatus = newStatus.toLowerCase().trim();
    await _db.ref('bookings/$bookingId').update({'status': normalizedStatus});
  }

  // 5a. Cancel Booking (release slot)
  Future<void> cancelBooking(String bookingId) async {
    await _bookingService.cancelBooking(bookingId);
  }

  // 5b. Reschedule Booking with slot lock
  Future<void> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    String newTime,
  ) async {
    final booking = await getBooking(bookingId);
    if (booking == null) return;

    await _bookingService.rescheduleBooking(
      bookingId: bookingId,
      providerId: booking.providerId,
      oldDate: booking.date,
      oldTime: booking.time,
      newDate: newDate,
      newTime: newTime,
    );
  }

  // 5c. Get Single Booking
  Future<Booking?> getBooking(String bookingId) async {
    final snapshot = await _db.ref('bookings/$bookingId').get();
    if (snapshot.exists && snapshot.value != null) {
      return Booking.fromMap(_asMap(snapshot.value), bookingId);
    }
    return null;
  }

  // 6. Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    await _db.ref('users/${user.id}').update(user.toMap());
  }

  // 7. Get Single User Stream
  Stream<UserModel?> getUserStream(String uid) {
    return _db.ref('users/$uid').onValue.map((event) {
      if (event.snapshot.value != null) {
        return UserModel.fromMap(_asMap(event.snapshot.value), uid);
      }
      return null;
    });
  }
}
