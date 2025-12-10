import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../core/time_utils.dart';
import '../models/user_model.dart';

class BookingService {
  BookingService(this._db);

  final FirebaseDatabase _db;
  static const int _lockTtlMs = 60000;

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

    final lockId =
        _db.ref('locks').push().key ??
        DateTime.now().microsecondsSinceEpoch.toString();

    await withRetry(() async {
      await _cleanupExpiredLock(availRef);
      await _placeLock(availRef, lockId, booking.seekerId);
      try {
        await bookingRef.set({
          'bookingId': bookingRef.key,
          'providerId': booking.providerId,
          'seekerId': booking.seekerId,
          'seekerName': booking.seekerName,
          'providerName': booking.providerName,
          'serviceId': booking.serviceId,
          'serviceName': booking.serviceName,
          'serviceCategory': booking.serviceCategory,
          'scheduleDate': slotDateKey,
          'scheduleTime': booking.time,
          'slotDate': slotDateKey,
          'slotTime': slotTimeKey,
          'slotUtc': slotUtc.toIso8601String(),
          'status': 'pending',
          'address': booking.address,
          'notes': booking.problemDescription,
          'problemDescription': booking.problemDescription,
          'priceCents': priceCents,
          'createdAt': ServerValue.timestamp,
        });

        await _finalizeBookingLock(
          availRef: availRef,
          lockId: lockId,
          priceCents: priceCents,
          providerId: booking.providerId,
          seekerId: booking.seekerId,
        );
      } catch (e) {
        await _releaseLock(availRef, lockId);
        rethrow;
      }
    }).timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('Network timeout'),
    );
  }

  Future<void> cancelBooking(String bookingId) async {
    final bookingSnap = await _db.ref('bookings/$bookingId').get();
    if (!bookingSnap.exists) return;
    final data = bookingSnap.value as Map?;
    final providerId = data?['providerId'] as String?;
    final slotDate = data?['slotDate'] as String?;
    final slotTime = data?['slotTime'] as String?;

    await withRetry(() async {
      if (providerId != null && slotDate != null && slotTime != null) {
        final slotRef = _db.ref('availability/$providerId/$slotDate/$slotTime');
        await slotRef.runTransaction((currentData) {
          if (currentData == null) return Transaction.abort();
          return Transaction.success({'status': 'open'});
        });
      }
      await _db.ref('bookings/$bookingId').update({'status': 'cancelled'});
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
          final root = Map<String, dynamic>.from((mutable as Map?) ?? {});

          Map<String, dynamic> path(String path) {
            return path.split('/').fold<Map<String, dynamic>>(root, (acc, seg) {
              final current = acc[seg];
              if (current is Map<String, dynamic>) {
                acc[seg] = current;
              } else if (current is Map) {
                acc[seg] = Map<String, dynamic>.from(current);
              } else {
                acc[seg] = <String, dynamic>{};
              }
              return acc[seg] as Map<String, dynamic>;
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

          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final newLockedAt = (newNode?['lockedAt'] as int?) ?? 0;
          final newLockExpired = newLockedAt == 0
              ? true
              : nowMs - newLockedAt > _lockTtlMs;

          if (!oldBooked || !newLockedByUs || newLockExpired) {
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
          newTarget['bookedAt'] = ServerValue.timestamp;

          final bookingTarget = path('bookings/$bookingId');
          bookingTarget['slotDate'] = newDateKey;
          bookingTarget['slotTime'] = newTimeKey;
          bookingTarget['slotUtc'] = newSlotUtc.toIso8601String();
          bookingTarget['status'] = 'pending';

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
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('Network timeout'),
    );
  }

  Future<void> _cleanupExpiredLock(DatabaseReference slotRef) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await slotRef.runTransaction((currentData) {
      final data = Map<String, dynamic>.from((currentData as Map?) ?? {});
      final status = data['status'] as String?;
      final lockedAt = (data['lockedAt'] as int?) ?? 0;
      final lockExpired =
          status == 'pending_lock' &&
          lockedAt > 0 &&
          nowMs - lockedAt > _lockTtlMs;

      if (lockExpired) {
        return Transaction.success({'status': 'open'});
      }
      return Transaction.success(data);
    });
  }

  Future<void> _placeLock(
    DatabaseReference slotRef,
    String lockId,
    String ownerId,
  ) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final result = await slotRef.runTransaction((currentData) {
      final data = Map<String, dynamic>.from((currentData as Map?) ?? {});
      final status = data['status'] as String?;
      final lockedAt = (data['lockedAt'] as int?) ?? 0;
      final lockOwner = data['lockOwner'] as String?;
      final lockExpired =
          status == 'pending_lock' &&
          lockedAt > 0 &&
          nowMs - lockedAt > _lockTtlMs;

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

    final snapshotOwner = (result.snapshot.value as Map?)?['lockOwner']
        ?.toString();
    if (snapshotOwner != lockId) {
      throw Exception('Lost slot lock');
    }
  }

  Future<void> _finalizeBookingLock({
    required DatabaseReference availRef,
    required String lockId,
    required int? priceCents,
    required String providerId,
    required String? seekerId,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final result = await availRef.runTransaction((currentData) {
      final data = Map<String, dynamic>.from((currentData as Map?) ?? {});
      final status = data['status'] as String?;
      final lockOwner = data['lockOwner'] as String?;
      final lockedAt = (data['lockedAt'] as int?) ?? 0;
      final lockExpired =
          status == 'pending_lock' &&
          lockedAt > 0 &&
          nowMs - lockedAt > _lockTtlMs;

      if (status != 'pending_lock' || lockOwner != lockId || lockExpired) {
        return Transaction.abort();
      }

      return Transaction.success({
        'status': 'booked',
        'providerId': providerId,
        if (seekerId != null) 'seekerId': seekerId,
        'bookedAt': ServerValue.timestamp,
        if (priceCents != null) 'priceCents': priceCents,
      });
    });

    if (!result.committed) {
      throw Exception('Slot lock expired before booking');
    }
  }

  Future<void> _releaseLock(DatabaseReference slotRef, String lockId) async {
    await slotRef.runTransaction((currentData) {
      final data = Map<String, dynamic>.from((currentData as Map?) ?? {});
      final lockOwner = data['lockOwner'] as String?;
      if (lockOwner != lockId) {
        return Transaction.success(data);
      }
      return Transaction.success({'status': 'open'});
    });
  }
}
