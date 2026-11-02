import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/chat/application/chat_providers.dart';
import 'package:pathfinders/features/chat/domain/chat_message.dart';

ChatMessage _message({
  required String id,
  required String senderId,
  required DateTime createdAt,
}) {
  return ChatMessage(
    id: id,
    senderId: senderId,
    senderName: 'Alex Doe',
    kind: ChatMessageKind.text,
    text: 'hello',
    createdAt: createdAt,
  );
}

void main() {
  group('countUnreadMessages', () {
    final lastSeen = DateTime(2026, 11, 2, 9);

    test('counts other members messages after last seen', () {
      final messages = [
        _message(
          id: '1',
          senderId: 'me',
          createdAt: lastSeen.add(const Duration(minutes: 1)),
        ),
        _message(
          id: '2',
          senderId: 'alex',
          createdAt: lastSeen.subtract(const Duration(minutes: 1)),
        ),
        _message(
          id: '3',
          senderId: 'alex',
          createdAt: lastSeen.add(const Duration(minutes: 2)),
        ),
      ];

      expect(
        countUnreadMessages(messages, lastSeen: lastSeen, currentUserId: 'me'),
        1,
      );
    });

    test('is zero when the thread is empty', () {
      expect(
        countUnreadMessages(const [], lastSeen: lastSeen, currentUserId: 'me'),
        0,
      );
    });

    test('is zero once everything has been seen', () {
      final messages = [
        _message(id: '1', senderId: 'alex', createdAt: lastSeen),
      ];

      expect(
        countUnreadMessages(messages, lastSeen: lastSeen, currentUserId: 'me'),
        0,
      );
    });
  });

  group('ChatMessage', () {
    test('exposes a point for location shares', () {
      final message = ChatMessage(
        id: '1',
        senderId: 'alex',
        senderName: 'Alex Doe',
        kind: ChatMessageKind.locationShare,
        latitude: 9.01,
        longitude: 38.75,
        createdAt: DateTime(2026, 11, 2),
      );

      expect(message.hasLocation, isTrue);
      expect(message.point?.latitude, 9.01);
      expect(message.point?.longitude, 38.75);
      expect(message.senderFirstName, 'Alex');
    });

    test('has no point for plain text', () {
      final message = _message(
        id: '1',
        senderId: 'alex',
        createdAt: DateTime(2026, 11, 2),
      );

      expect(message.hasLocation, isFalse);
      expect(message.point, isNull);
      expect(message.isDestinationUpdate, isFalse);
    });
  });
}
