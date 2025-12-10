final _urlRegex = RegExp(r'^(https?:\/\/[^\s]+)$');
const String kFallbackPhoto =
    'https://via.placeholder.com/150?text=Provider+Unavailable';

String? validatedUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (_urlRegex.hasMatch(trimmed)) return trimmed;
  return null;
}

String safePhotoUrl(String? url) =>
    validatedUrl(url) ?? kFallbackPhoto;


