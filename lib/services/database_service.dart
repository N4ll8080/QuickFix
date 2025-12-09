import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // 1. Get Providers by Category
  Stream<List<UserModel>> getProvidersByCategory(String category) {
    return _db.ref('users').onValue.map((event) {
      final List<UserModel> providers = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> users =
            event.snapshot.value as Map<dynamic, dynamic>;

        users.forEach((key, value) {
          final user = UserModel.fromMap(value, key);
          // Filter: Must be a provider AND match the category
          if (user.userType == 'provider' && user.category == category) {
            providers.add(user);
          }
        });
      }
      return providers;
    });
  }

  // 2. Create a Booking
  Future<void> createBooking(Booking booking) async {
    final newBookingRef = _db.ref('bookings').push();
    await newBookingRef.set(booking.toMap());
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
            final Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;
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
            final Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              bookings.add(Booking.fromMap(value, key));
            });
          }
          bookings.sort((a, b) => b.date.compareTo(a.date));
          return bookings;
        });
  }

  // 5. Update Booking Status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _db.ref('bookings/$bookingId').update({'status': newStatus});
  }

  // 6. Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    await _db.ref('users/${user.id}').update(user.toMap());
  }

  // 7. Get Single User Stream
  Stream<UserModel?> getUserStream(String uid) {
    return _db.ref('users/$uid').onValue.map((event) {
      if (event.snapshot.value != null) {
        return UserModel.fromMap(
          event.snapshot.value as Map<dynamic, dynamic>,
          uid,
        );
      }
      return null;
    });
  }
}
