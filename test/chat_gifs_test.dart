import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/chat/data/giphy_client.dart';
import 'package:pathfinders/features/chat/domain/chat_gif.dart';
import 'package:pathfinders/features/chat/domain/chat_message.dart';
import 'package:pathfinders/features/chat/domain/chat_notification.dart';

ChatMessage _gif() => ChatMessage(
  id: 'g1',
  senderId: 'hana',
  senderName: 'Hana Bekele',
  kind: ChatMessageKind.gif,
  gifUrl: 'https://media.giphy.com/media/abc/giphy.gif',
  createdAt: DateTime(2026, 11, 19, 12),
);

Map<String, dynamic> _response({required Map<String, dynamic> images}) => {
  'data': [
    {'id': 'abc', 'content_description': 'A cat waving', 'images': images},
  ],
};

void main() {
  group('isAllowedGifUrl', () {
    test('accepts Giphy media hosts over https', () {
      expect(
        isAllowedGifUrl('https://media.giphy.com/media/abc/giphy.gif'),
        isTrue,
      );
      expect(
        isAllowedGifUrl('https://i.giphy.com/media/abc/giphy.webp'),
        isTrue,
      );
      expect(
        isAllowedGifUrl('https://media2.giphy.com/media/abc/giphy.mp4'),
        isTrue,
      );
    });

    test('rejects other schemes, hosts and lookalikes', () {
      expect(isAllowedGifUrl(null), isFalse);
      expect(isAllowedGifUrl('not a url'), isFalse);
      expect(
        isAllowedGifUrl('http://media.giphy.com/media/abc/giphy.gif'),
        isFalse,
      );
      expect(isAllowedGifUrl('https://giphy.com.evil.io/abc.gif'), isFalse);
      expect(isAllowedGifUrl('https://example.com/abc.gif'), isFalse);
      expect(isAllowedGifUrl('https://media.giphy.com'), isFalse);
    });
  });

  group('ChatMessage', () {
    test('quotes a GIF without leaking its URL', () {
      expect(_gif().quotePreview, 'GIF');
      expect(_gif().isGif, isTrue);
    });

    test('has no text body to render', () {
      expect(_gif().text, isNull);
    });
  });

  test('notifies a GIF with its own line', () {
    expect(chatNotificationBody(_gif()), 'Sent a GIF');
  });

  group('GiphyClient.parseResults', () {
    test('prefers the larger rendition but keeps a small preview', () {
      final results = GiphyClient.parseResults(
        _response(
          images: {
            'fixed_width': {
              'url': 'https://media.giphy.com/media/abc/200w.gif',
            },
            'downsized_medium': {
              'url': 'https://media.giphy.com/media/abc/480w.gif',
            },
          },
        ),
      );

      expect(results, hasLength(1));
      final gif = results.single;
      expect(gif.id, 'abc');
      expect(gif.title, 'A cat waving');
      expect(gif.url, 'https://media.giphy.com/media/abc/480w.gif');
      expect(gif.previewUrl, 'https://media.giphy.com/media/abc/200w.gif');
    });

    test('falls back through the rendition chain', () {
      final results = GiphyClient.parseResults(
        _response(
          images: {
            'fixed_width_downsampled': {
              'url': 'https://media.giphy.com/media/abc/200w-down.gif',
            },
          },
        ),
      );

      expect(
        results.single.url,
        'https://media.giphy.com/media/abc/200w-down.gif',
      );
      expect(results.single.previewUrl, results.single.url);
    });

    test('drops items whose media is not served by Giphy', () {
      final results = GiphyClient.parseResults(
        _response(
          images: {
            'fixed_width': {'url': 'https://example.com/tracker.gif'},
          },
        ),
      );

      expect(results, isEmpty);
      expect(GiphyClient.parseResults('nonsense'), isEmpty);
      expect(GiphyClient.parseResults({'data': 'nonsense'}), isEmpty);
    });
  });
}
