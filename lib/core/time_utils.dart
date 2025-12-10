import 'package:intl/intl.dart';

/// Time helpers to guarantee UTC storage and HH-mm path tokens.
String dateKeyUtc(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt.toUtc());

String timeKeyUtc(DateTime dt) => DateFormat('HH-mm').format(dt.toUtc());

String isoUtc(DateTime dt) => dt.toUtc().toIso8601String();

final _legacyTimeRegex = RegExp(r'^\d{1,2}:\d{2} (AM|PM)$');
final _timeKeyRegex = RegExp(r'^\d{2}-\d{2}$');

bool isLegacyTimeKey(String key) => _legacyTimeRegex.hasMatch(key);

bool isTimeKey(String key) => _timeKeyRegex.hasMatch(key);

/// Convert a display time (e.g., "2:00 PM" or "14-00") into an HH-mm token.
String normalizeTimeKey(String display) {
  final cleaned = display.trim();
  if (isTimeKey(cleaned)) return cleaned;
  if (_legacyTimeRegex.hasMatch(cleaned)) {
    final parsed = DateFormat('h:mm a').parse(cleaned);
    return DateFormat('HH-mm').format(parsed);
  }
  // Fallback: try generic parsing, else return as-is to avoid crashes.
  try {
    final parsed = DateFormat('Hm').parse(cleaned);
    return DateFormat('HH-mm').format(parsed);
  } catch (_) {
    return cleaned.replaceAll(':', '-');
  }
}

/// Convert a slot key (HH-mm) back to a display-friendly 12-hour string.
String displayTimeFromKey(String key) {
  if (isTimeKey(key)) {
    final parsed = DateFormat('HH-mm').parseUtc(key);
    return DateFormat('h:mm a').format(parsed.toLocal());
  }
  return key;
}

/// Safely normalize a day's map of slot keys, ignoring legacy keys.
Map<String, dynamic> normalizeSlotKeys(Map<String, dynamic> day) {
  final result = <String, dynamic>{};
  day.forEach((k, v) {
    if (isLegacyTimeKey(k)) return;
    result[k] = v;
  });
  return result;
}

/// Build a UTC DateTime from a local date (no time) and display time string.
DateTime combineDateAndTimeUtc(DateTime localDate, String displayTime) {
  final timeKey = normalizeTimeKey(displayTime);
  DateTime parsed;
  if (isTimeKey(timeKey)) {
    parsed = DateFormat('HH-mm').parse(timeKey, true); // treat as UTC
  } else {
    parsed = DateFormat('HH-mm').parseUtc('00-00');
  }
  // Use the provided local date components but return as UTC.
  return DateTime.utc(
    localDate.year,
    localDate.month,
    localDate.day,
    parsed.hour,
    parsed.minute,
  );
}

bool isUtcInFuture(DateTime slotUtc) => slotUtc.isAfter(DateTime.now().toUtc());


