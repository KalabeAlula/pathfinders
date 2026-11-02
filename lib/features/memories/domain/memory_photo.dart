import 'dart:typed_data';

/// A photo the composer has picked but not uploaded yet.
class MemoryPhotoDraft {
  const MemoryPhotoDraft({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;

  /// Mirrors the bucket's `file_size_limit`; refuse early with a clear error.
  static const maxBytes = 8 * 1024 * 1024;

  static const allowedContentTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
  };

  static bool isAllowed(String contentType) =>
      allowedContentTypes.contains(contentType);

  /// Uses the picker's hint when it is one we accept, otherwise falls back to
  /// the file name. Returns null for formats the bucket will not accept.
  static String? contentTypeFor(String? mimeType, String fileName) {
    final hint = mimeType?.toLowerCase().trim();
    if (hint != null && isAllowed(hint)) return hint;

    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    if (name.endsWith('.heif')) return 'image/heif';
    if (name.endsWith('.gif') ||
        name.endsWith('.bmp') ||
        name.endsWith('.tif') ||
        name.endsWith('.tiff') ||
        name.endsWith('.svg')) {
      return null;
    }
    return 'image/jpeg';
  }

  static String extensionFor(String contentType) => switch (contentType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/heic' => 'heic',
    'image/heif' => 'heif',
    _ => 'jpg',
  };
}
