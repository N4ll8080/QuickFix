import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../core/time_utils.dart';
import '../models/user_model.dart';

class BookingService {
  BookingService(this._db);

  final FirebaseDatabase _db;
  static const int _lockTtlMs = 300000; // 5 minutes

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

  Future<void> bookSlot({
    required Booking booking,
    required int priceCents,
  }) async {
    final slotDateKey = dateKeyUtc(booking.date);
    final slotTimeKey = normalizeTimeKey(booking.time);
    final slotUtc = combineDateAndTimeUtc(booking.date, booking.time);

    final availRef = _db.ref(
      'availability/${booking.providerId}/$slotDateKey/$slotTimeKey',
    );
    final bookingRef = _db.ref('bookings').push();

    // --- THIS IS THE MISSING DECLARATION ---
    final lockId =
        _db.ref('locks').push().key ??
        DateTime.now().microsecondsSinceEpoch.toString();
    // ---------------------------------------

    try {
      await withRetry(() async {
        // 1. Clean up old locks
        await _cleanupExpiredLock(availRef);

        // 2. Place new lock
        await _placeLock(availRef, lockId, booking.seekerId);

        // 3. Prepare Booking Data
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
          'status': 'Pending',
          'address': booking.address.toString(),
          'notes': booking.problemDescription.toString(),
          'problemDescription': booking.problemDescription.toString(),
          'priceCents': priceCents,
          'createdAt': ServerValue.timestamp,
        };

        // 4. Save to Database
        await bookingRef.set(bookingData);

        // 5. Finalize the lock (convert to booked status)
        await _finalizeBookingLock(
          availRef: availRef,
          lockId: lockId,
          priceCents: priceCents,
          providerId: booking.providerId,
          seekerId: booking.seekerId,
        );
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Network timeout'),
      );
    } catch (e) {
      // Clean up on failure
      try {
        await _releaseLock(availRef, lockId);
      } catch (_) {
        // Best effort cleanup
      }
      rethrow;
    }
  }

  Future<void> _assertBookingPreconditions({
    required String seekerId,
    required String providerId,
    required DatabaseReference availRef,
  }) async {
    // Validate the caller has seeker role; rules also enforce, but this
    // provides a clearer client error before we attempt the transaction.
    final roleSnap = await _db.ref('users/$seekerId/userType').get();
    final role = roleSnap.value?.toString().toLowerCase();
    if (role != 'seeker' && seekerId != providerId) {
      throw Exception('Permission denied: account is not a seeker');
    }

    // If slot is already booked, fail fast with a readable error.
    final slotSnap = await availRef.get();
    final slot = _asMap(slotSnap.value);
    if ((slot['status'] as String?) == 'booked') {
      throw Exception('Slot already booked');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final bookingSnap = await _db.ref('bookings/$bookingId').get();
    if (!bookingSnap.exists) return;
    final data = _asMap(bookingSnap.value);
    final providerId = data['providerId'] as String?;
    final slotDate = data['slotDate'] as String?;
    final slotTime = data['slotTime'] as String?;

    await withRetry(() async {
      if (providerId != null && slotDate != null && slotTime != null) {
        final slotRef = _db.ref('availability/$providerId/$slotDate/$slotTime');
        await slotRef.set({'status': 'open'});
      }
      await _db.ref('bookings/$bookingId').update({'status': 'Cancelled'});
    });
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required String providerId,
    required DateTime oldDate,
    required String oldTime,
    required DateTime newDate,
    required String newTime,
  }) async {
    final oldDateKey = dateKeyUtc(oldDate);
    final oldTimeKey = normalizeTimeKey(oldTime);
    final newDateKey = dateKeyUtc(newDate);
    final newTimeKey = normalizeTimeKey(newTime);
    final newSlotUtc = combineDateAndTimeUtc(newDate, newTime);

    final rootRef = _db.ref();
    final newSlotRef = _db.ref(
      'availability/$providerId/$newDateKey/$newTimeKey',
    );
    final lockId =
        _db.ref('locks').push().key ??
        DateTime.now().microsecondsSinceEpoch.toString();

    await withRetry(() async {
      await _cleanupExpiredLock(newSlotRef);
      await _placeLock(newSlotRef, lockId, providerId);

      try {
        final result = await rootRef.runTransaction((mutable) {
          final root = _asMap(mutable);

          Map<String, dynamic> path(String path) {
            return path.split('/').fold<Map<String, dynamic>>(root, (acc, seg) {
              final coerced = _asMap(acc[seg]);
              acc[seg] = coerced;
              return coerced;
            });
          }

          Map<String, dynamic>? pathOrNull(String path) {
            final parts = path.split('/');
            Map<String, dynamic>? acc = root;
            for (final seg in parts) {
              final next = acc?[seg];
              if (next is Map<String, dynamic>) {
                acc = next;
              } else if (next is Map) {
                acc = Map<String, dynamic>.from(next);
              } else {
                return null;
              }
            }
            return acc;
          }

          final oldNode = pathOrNull(
            'availability/$providerId/$oldDateKey/$oldTimeKey',
          );
          final newNode = pathOrNull(
            'availability/$providerId/$newDateKey/$newTimeKey',
          );

          final oldBooked = oldNode != null && oldNode['status'] == 'booked';
          final newLockedByUs =
              newNode != null &&
              newNode['lockOwner'] == lockId &&
              newNode['status'] == 'pending_lock';

          if (!oldBooked || !newLockedByUs) {
            return Transaction.abort();
          }

          final oldTarget = path(
            'availability/$providerId/$oldDateKey/$oldTimeKey',
          );
          oldTarget['status'] = 'open';
          oldTarget.remove('lockOwner');
          oldTarget.remove('lockedAt');

          final newTarget = path(
            'availability/$providerId/$newDateKey/$newTimeKey',
          );
          newTarget['status'] = 'booked';
          newTarget['lockOwner'] = lockId;
          newTarget['bookedAt'] = DateTime.now().toUtc().toIso8601String();

          final bookingTarget = path('bookings/$bookingId');
          bookingTarget['slotDate'] = newDateKey;
          bookingTarget['slotTime'] = newTimeKey;
          bookingTarget['slotUtc'] = newSlotUtc.toIso8601String();
          bookingTarget['status'] = 'Pending';

          return Transaction.success(root);
        });

        if (!result.committed) {
          throw Exception('Slot unavailable for reschedule');
        }

        await _finalizeBookingLock(
          availRef: newSlotRef,
          lockId: lockId,
          priceCents: null,
          providerId: providerId,
          seekerId: null,
        );
      } catch (e) {
        await _releaseLock(newSlotRef, lockId);
        rethrow;
      }
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Network timeout'),
    );
  }

  Future<void> _cleanupExpiredLock(DatabaseReference slotRef) async {
    final snapshot = await slotRef.get();
    if (!snapshot.exists) {
      await slotRef.set({'status': 'open'});
      return;
    }

    final raw = snapshot.value;

    // Handle legacy/string values (e.g. "open") by normalizing to map shape
    if (raw is! Map) {
      await slotRef.set({'status': 'open'});
      return;
    }

    final data = Map<String, dynamic>.from(raw);

    final status = data['status'] as String?;
    if (status != 'pending_lock') return;

    final lockedAt = (data['lockedAt'] as int?) ?? 0;
    if (lockedAt == 0) {
      await slotRef.set({'status': 'open'});
      return;
    }

    final serverTimeSnapshot = await _db.ref('.info/serverTimeOffset').get();
    final serverOffset = (serverTimeSnapshot.value as int?) ?? 0;
    final serverTime = DateTime.now().millisecondsSinceEpoch + serverOffset;

    if (serverTime - lockedAt > _lockTtlMs) {
      await slotRef.set({'status': 'open'});
    }
  }

  Future<void> _placeLock(
    DatabaseReference slotRef,
    String lockId,
    String ownerId,
  ) async {
    final serverTimeSnapshot = await _db.ref('.info/serverTimeOffset').get();
    final serverOffset = (serverTimeSnapshot.value as int?) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch + serverOffset;

    final result = await slotRef.runTransaction((currentData) {
      // CHANGE: Use _asMap to safely handle Strings ("open") vs Maps
      final data = _asMap(currentData);

      final status = data['status'] as String?;
      final lockedAt = (data['lockedAt'] as int?) ?? 0;
      final lockOwner = data['lockOwner'] as String?;

      final lockExpired =
          status == 'pending_lock' &&
          lockedAt > 0 &&
          nowMs - lockedAt > _lockTtlMs;

      // Treat null status (from "open" string) as free
      final isFree =
          status == null ||
          status == 'open' ||
          lockExpired ||
          (status == 'pending_lock' && lockOwner == lockId);

      if (!isFree) return Transaction.abort();

      return Transaction.success({
        'status': 'pending_lock',
        'lockOwner': lockId,
        'lockedAt': ServerValue.timestamp,
        'ownerId': ownerId,
      });
    });

    if (!result.committed) {
      throw Exception('Slot unavailable');
    }

    final verifySnapshot = await slotRef.get();
    // CHANGE: Use _asMap here too
    final verifyData = _asMap(verifySnapshot.value);

    if (verifyData['lockOwner'] != lockId) {
      throw Exception('Lost slot lock to another client');
    }
  }

  Future<void> _finalizeBookingLock({
    required DatabaseReference availRef,
    required String lockId,
    required int? priceCents,
    required String providerId,
    required String? seekerId,
  }) async {
    final currentSnapshot = await availRef.get();
    // CHANGE: Use _asMap
    final currentData = _asMap(currentSnapshot.value);
    final currentLockedAt = currentData['lockedAt'];

    final result = await availRef.runTransaction((currentData) {
      // CHANGE: Use _asMap
      final data = _asMap(currentData);

      final status = data['status'] as String?;
      final lockOwner = data['lockOwner'] as String?;

      if (status != 'pending_lock' || lockOwner != lockId) {
        return Transaction.abort();
      }

      final updateData = <String, dynamic>{
        'status': 'booked',
        'lockOwner': lockId,
        'providerId': providerId,
        // Keep the original timestamp
        'lockedAt': currentLockedAt,
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
      // CHANGE: Use _asMap
      final data = _asMap(currentData);

      final lockOwner = data['lockOwner'] as String?;
      if (lockOwner != lockId) {
        // Return original data (safely) if we don't own it
        return Transaction.success(currentData);
      }
      return Transaction.success({'status': 'open'});
    });
  }

  // Helper to safely convert Strings or Maps into a Map<String, dynamic>
  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    // If it's a String (like "open") or null, return empty map so checks default to null/safe
    return <String, dynamic>{};
  }
}
