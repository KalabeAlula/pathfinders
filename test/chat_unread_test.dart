import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:pathfinders/features/chat/application/chat_providers.dart';
import 'package:pathfinders/features/chat/data/chat_seen_store.dart';
import 'package:pathfinders/features/chat/domain/chat_message.dart';
import 'package:pathfinders/features/chat/domain/chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this.messages);

  final List<ChatMessage> messages;

  @override
  Stream<List<ChatMessage>> watchMessages() => Stream.value(messages);

  @override
  Future<void> sendText({
    required String senderId,
    required String text,
  }) async {}

  @override
  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('chatUnreadCountProvider', () {
    test('counts on its own and clears once the thread is opened', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final openedAt = DateTime.now().subtract(const Duration(minutes: 2));
      await ChatSeenStore(preferences).write('c1', openedAt);

      final messages = [
        _message(
          id: '1',
          senderId: 'alex',
          createdAt: openedAt.add(const Duration(minutes: 1)),
        ),
        _message(
          id: '2',
          senderId: 'me',
          createdAt: openedAt.add(const Duration(minutes: 1)),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          chatRepositoryProvider('c1')
              .overrideWithValue(_FakeChatRepository(messages)),
        ],
      );
      addTearDown(container.dispose);

      final query = (circleId: 'c1', userId: 'me');
      final subscription = container.listen(
        chatUnreadCountProvider(query),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(circleMessagesProvider('c1').future);

      expect(container.read(chatUnreadCountProvider(query)), 1);

      container.read(chatSeenControllerProvider('c1').notifier).markSeen();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(container.read(chatUnreadCountProvider(query)), 0);
      final stored = ChatSeenStore(preferences).read('c1');
      expect(stored, isNotNull);
      expect(stored!.isAfter(messages.first.createdAt), isTrue);
    });
  });
}
