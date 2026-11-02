import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/memories/domain/memory_photo.dart';

void main() {
  group('MemoryPhotoDraft', () {
    test('prefers a supported picker hint over the file name', () {
      expect(
        MemoryPhotoDraft.contentTypeFor('image/png', 'IMG_0042.jpg'),
        'image/png',
      );
    });

    test('falls back to the file extension when the hint is generic', () {
      expect(
        MemoryPhotoDraft.contentTypeFor(
          'application/octet-stream',
          'IMG_0042.HEIC',
        ),
        'image/heic',
      );
      expect(MemoryPhotoDraft.contentTypeFor(null, 'shot.webp'), 'image/webp');
      expect(
        MemoryPhotoDraft.contentTypeFor(null, 'unknown.bin'),
        'image/jpeg',
      );
    });

    test('refuses formats the private bucket will not accept', () {
      expect(MemoryPhotoDraft.contentTypeFor('image/gif', 'loop.gif'), isNull);
      expect(MemoryPhotoDraft.contentTypeFor(null, 'scan.tiff'), isNull);
    });

    test('maps accepted content types back to extensions', () {
      expect(MemoryPhotoDraft.extensionFor('image/jpeg'), 'jpg');
      expect(MemoryPhotoDraft.extensionFor('image/png'), 'png');
      expect(MemoryPhotoDraft.extensionFor('image/webp'), 'webp');
      expect(MemoryPhotoDraft.extensionFor('image/heic'), 'heic');
    });

    test('knows which content types the bucket allows', () {
      expect(MemoryPhotoDraft.isAllowed('image/heic'), isTrue);
      expect(MemoryPhotoDraft.isAllowed('image/gif'), isFalse);
    });
  });
}
