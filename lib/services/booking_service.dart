import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../core/time_utils.dart';
import '../models/user_model.dart';

class BookingService {
  BookingService(this._db);

  final FirebaseDatabase _db;
  static const int _lockTtlMs = 300000; // 5 minutes

  // Valid booking status values (all lowercase)
  static const Set<String> _validStatuses = {
    'pending',
    'requested',
    'accepted',
    'confirmed',
    'declined',
    'cancelled',
    'in progress',
    'completed',
    'rescheduled',
  };

  String _normalizeStatus(String status) {
    final normalized = status.toLowerCase().trim();
    if (!_validStatuses.contains(normalized)) {
      throw ArgumentError('Invalid booking status: "$status"');
    }
    return normalized;
  }

  Future<int> fetchPriceCents(String providerId) async {
    final snap = await _db.ref('users/$providerId/rate').get();
    final rate = snap.value;
    if (rate == null) return 0;
    final doubleValue = double.tryParse(rate.toString()) ?? 0;
    return (doubleValue * 100).round();
  }

  Future<T> withRetry<T>(Future<T> Function() fn, {int retries = 3}) async {
    for (var i = 0; i < retries; i++) {
      try {
        return await fn();
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
      }
    }
    throw Exception('Retry limit reached');
  }

  // --- SAFE MAP CONVERTER ---
  Map<String, dynamic> _asMap(dynamic value) {
    if (value == null) return <String, dynamic>{'status': 'open'};
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) return <String, dynamic>{'status': value};
    return <String, dynamic>{'status': 'open'};
  }

  Future<void> bookSlot({
    required Booking booking,
    required int priceCents,
  }) async {
    print('DEBUG: Starting bookSlot...');
    final slotDateKey = dateKeyUtc(booking.date);
    final slotTimeKey = normalizeTimeKey(booking.time);
    final slotUtc = combineDateAndTimeUtc(booking.date, booking.time);

    final availRef = _db.ref(
      'availability/${booking.providerId}/$slotDateKey/$slotTimeKey',
    );
    final bookingRef = _db.ref('bookings').push();

    // Create a lock ID (ensure it's not null)
    final lockId =
        _db.ref('locks').push().key ??
        DateTime.now().microsecondsSinceEpoch.toString();
    print('DEBUG: LockID generated: $lockId');

    try {
      await withRetry(() async {
        // 1. Clean up old locks
        print('DEBUG: Cleaning expired locks...');
        await _cleanupExpiredLock(availRef);

        // 2. Place new lock
        print('DEBUG: Placing new lock...');
        await _placeLock(availRef, lockId, booking.seekerId);

        // 3. Prepare Booking Data
        print('DEBUG: Preparing booking data...');
        final normalizedStatus = _normalizeStatus(booking.status);
        final bookingData = <String, Object?>{
          'bookingId': bookingRef.key,
          'providerId': booking.providerId,
          'seekerId': booking.seekerId,
          'seekerName': booking.seekerName.toString(),
          'providerName': booking.providerName.toString(),
          'serviceId': booking.serviceId.toString(),
          'serviceName': booking.serviceName.toString(),
          'serviceCategory': booking.serviceCategory.toString(),
          'scheduleDate': slotDateKey,
          'scheduleTime': slotTimeKey,
          'slotDate': slotDateKey,
          'slotTime': slotTimeKey,
          'slotUtc': slotUtc.toIso8601String(),
          'status': normalizedStatus,
          'address': booking.address.toString(),
          'notes': booking.problemDescription.toString(),
          'problemDescription': booking.problemDescription.toString(),
          'priceCents': priceCents,
          'createdAt': ServerValue.timestamp,
        };

        // 4. Save to Database
        print('DEBUG: Writing to bookings table...');
        await bookingRef.set(bookingData);

        // 5. Finalize the lock
        print('DEBUG: Finalizing booking lock...');
        await _finalizeBookingLock(
          availRef: availRef,
          lockId: lockId,
          priceCents: priceCents,
          providerId: booking.providerId,
          seekerId: booking.seekerId,
        );
        print('DEBUG: bookSlot SUCCESS');
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Network timeout'),
      );
    } catch (e, stack) {
      print('DEBUG ERROR in bookSlot: $e');
      print(stack);
      // Clean up on failure
      try {
        print('DEBUG: Attempting to release lock due to error...');
        await _releaseLock(availRef, lockId);
      } catch (_) {
        print('DEBUG: Failed to release lock during cleanup');
      }
      rethrow;
    }
  }

  Future<void> _cleanupExpiredLock(DatabaseReference slotRef) async {
    final snapshot = await slotRef.get();
    if (!snapshot.exists) {
      // Ensure we write a Map, not a String
      await slotRef.set({'status': 'open'});
      return;
    }

    final data = _asMap(snapshot.value);
    final status = data['status'] as String?;

    if (status != 'pending_lock') return;

    final lockedAt = (data['lockedAt'] as int?) ?? 0;
    if (lockedAt == 0) {
      await slotRef.set({'status': 'open'});
      return;
    }

    final nowMs =
        DateTime.now().millisecondsSinceEpoch; // Simplified time check
    if (nowMs - lockedAt > _lockTtlMs) {
      print('DEBUG: Found expired lock, resetting to open.');
      await slotRef.set({'status': 'open'});
    }
  }

  Future<void> _placeLock(
    DatabaseReference slotRef,
    String lockId,
    String ownerId,
  ) async {
    final result = await slotRef.runTransaction((currentData) {
      // 1. SAFELY Convert current data to Map
      final data = _asMap(currentData);

      final status = data['status'] as String?;
      final lockedAt = (data['lockedAt'] as int?) ?? 0;
      final lockOwner = data['lockOwner'] as String?;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final lockExpired =
          status == 'pending_lock' &&
          lockedAt > 0 &&
          nowMs - lockedAt > _lockTtlMs;

      // Treat "open", null, expired, or "our own lock" as free
      final isFree =
          status == null ||
          status == 'open' ||
          lockExpired ||
          (status == 'pending_lock' && lockOwner == lockId);

      if (!isFree) {
        return Transaction.abort();
      }

      // 2. Return a proper MAP object
      return Transaction.success({
        'status': 'pending_lock',
        'lockOwner': lockId,
        'lockedAt': ServerValue.timestamp,
        'ownerId': ownerId,
      });
    });

    if (!result.committed) {
      throw Exception('Slot unavailable (Transaction failed)');
    }
  }

  Future<void> _finalizeBookingLock({
    required DatabaseReference availRef,
    required String lockId,
    required int? priceCents,
    required String providerId,
    required String? seekerId,
  }) async {
    // We don't need to fetch 'currentSnapshot' here manually, transaction handles it.

    final result = await availRef.runTransaction((currentData) {
      final data = _asMap(currentData);

      final status = data['status'] as String?;
      final lockOwner = data['lockOwner'] as String?;

      if (status != 'pending_lock' || lockOwner != lockId) {
        return Transaction.abort(); // Lost the lock
      }

      // Preserve existing lockedAt if possible
      final currentLockedAt = data['lockedAt'];

      final updateData = <String, dynamic>{
        'status': 'booked',
        'lockOwner': lockId,
        'providerId': providerId,
        'lockedAt': currentLockedAt ?? ServerValue.timestamp,
        'bookedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (seekerId != null) updateData['seekerId'] = seekerId;
      if (priceCents != null) updateData['priceCents'] = priceCents;

      return Transaction.success(updateData);
    });

    if (!result.committed) {
      print('Warning: Failed to finalize booking lock');
    }
  }

  Future<void> _releaseLock(DatabaseReference slotRef, String lockId) async {
    await slotRef.runTransaction((currentData) {
      final data = _asMap(currentData);
      if (data['lockOwner'] != lockId) {
        return Transaction.success(data); // Don't touch if not ours
      }
      return Transaction.success({'status': 'open'});
    });
  }

  // --- Missing methods implementation required for compilation ---
  Future<void> cancelBooking(String bookingId) async {
    /* Implementation from previous file */
  }
  Future<void> rescheduleBooking({
    required String bookingId,
    required String providerId,
    required DateTime oldDate,
    required String oldTime,
    required DateTime newDate,
    required String newTime,
  }) async {
    /* Implementation from previous file */
  }
}
