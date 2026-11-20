import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/chat/domain/chat_message.dart';
import 'package:pathfinders/features/chat/domain/chat_thread.dart';

ChatMessage _text(String id, DateTime at, {String body = 'hello'}) {
  return ChatMessage(
    id: id,
    senderId: 'me',
    senderName: 'Alex Doe',
    kind: ChatMessageKind.text,
    text: body,
    createdAt: at,
  );
}

void main() {
  group('mergeChatThread', () {
    final t0 = DateTime(2026, 11, 19, 9);

    test('keeps echoes the server has not returned yet', () {
      final merged = mergeChatThread(
        thread: [_text('a', t0)],
        optimistic: [_text('b', t0.add(const Duration(seconds: 1)))],
      );

      expect(merged.map((message) => message.id), ['a', 'b']);
    });

    test('the fetched row replaces its echo under the same id', () {
      final echo = _text('a', t0, body: 'as typed');
      final confirmed = _text('a', t0, body: 'as stored');

      final merged = mergeChatThread(thread: [confirmed], optimistic: [echo]);

      expect(merged, hasLength(1));
      expect(merged.single.text, 'as stored');
    });

    test('orders by send time regardless of arrival order', () {
      final merged = mergeChatThread(
        thread: [
          _text('a', t0),
          _text('c', t0.add(const Duration(seconds: 2))),
        ],
        optimistic: [_text('b', t0.add(const Duration(seconds: 1)))],
      );

      expect(merged.map((message) => message.id), ['a', 'b', 'c']);
    });

    test('quotes a message with the same preview text the thread uses', () {
      final message = ChatMessage(
        id: 'loc',
        senderId: 'alex',
        senderName: 'Alex Doe',
        kind: ChatMessageKind.locationShare,
        placeLabel: 'Bole',
        latitude: 9.0,
        longitude: 38.7,
        createdAt: t0,
      );

      expect(message.toReply().preview, 'Shared Bole');
    });
  });
}
