import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/chat/application/chat_notification_providers.dart';
import 'package:pathfinders/features/chat/domain/chat_message.dart';
import 'package:pathfinders/features/chat/domain/chat_notification.dart';

ChatMessage _message({
  required String id,
  required String senderId,
  String senderName = 'Hana Bekele',
  String text = 'Dinner at 7?',
  ChatMessageKind kind = ChatMessageKind.text,
}) {
  final located = kind == ChatMessageKind.locationShare;
  return ChatMessage(
    id: id,
    senderId: senderId,
    senderName: senderName,
    kind: kind,
    text: kind == ChatMessageKind.text ? text : null,
    placeLabel: located ? 'Entoto Park' : null,
    latitude: located ? 9.09 : null,
    longitude: located ? 38.77 : null,
    createdAt: DateTime(2026, 11, 7, 12),
  );
}

void main() {
  group('ChatNotification', () {
    test('titles the shade with the sender and the circle', () {
      final notification = ChatNotification.fromMessage(
        message: _message(id: 'm1', senderId: 'hana', text: 'See you there'),
        circleId: 'c1',
        circleName: 'Simien Pair',
      );

      expect(notification.title, 'Hana Bekele • Simien Pair');
      expect(notification.body, 'See you there');
      expect(chatCircleFromPayload(notification.payload), 'c1');
    });

    test('summarises a shared location instead of its empty body', () {
      final notification = ChatNotification.fromMessage(
        message: _message(
          id: 'm2',
          senderId: 'hana',
          kind: ChatMessageKind.locationShare,
        ),
        circleId: 'c1',
        circleName: 'Simien Pair',
      );

      expect(notification.body, '📍 Shared a location');
    });

    test('builds the same entry from a cloud push', () {
      final notification = ChatNotification.fromPush(
        messageId: 'm3',
        circleId: 'c1',
        senderName: 'Hana Bekele',
        title: 'Hana Bekele • Simien Pair',
        body: '📍 Shared a location',
      );

      expect(notification.title, 'Hana Bekele • Simien Pair');
      expect(notification.body, '📍 Shared a location');
      expect(chatCircleFromPayload(notification.payload), 'c1');
      expect(
        notification.id,
        ChatNotification.fromPush(
          messageId: 'm3',
          circleId: 'c1',
          senderName: 'Hana Bekele',
          title: 'Hana Bekele • Simien Pair',
          body: '📍 Shared a location',
        ).id,
      );
      expect(
        notification.id,
        isNot(
          ChatNotification.fromPush(
            messageId: 'm4',
            circleId: 'c1',
            senderName: 'Hana Bekele',
            title: 'Hana Bekele • Simien Pair',
            body: 'See you there',
          ).id,
        ),
      );
    });

    test('ignores payloads that are not chat taps', () {
      expect(chatCircleFromPayload(null), isNull);
      expect(chatCircleFromPayload('not json'), isNull);
      expect(chatCircleFromPayload(jsonEncode({'circle_id': 'c1'})), isNull);
      expect(
        chatCircleFromPayload(
          jsonEncode({'kind': 'warmth', 'circle_id': 'c1'}),
        ),
        isNull,
      );
      expect(
        chatCircleFromPayload(jsonEncode({'kind': 'chat', 'circle_id': ''})),
        isNull,
      );
    });

    test('scopes grouping to one circle', () {
      expect(
        ChatNotification.groupKeyFor('c1'),
        isNot(ChatNotification.groupKeyFor('c2')),
      );
      expect(
        ChatNotification.summaryIdFor('c1'),
        isNot(ChatNotification.summaryIdFor('c2')),
      );
    });
  });

  group('ChatNotificationTarget', () {
    test('holds a tapped circle until the shell consumes it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(chatNotificationTargetProvider), isNull);
      container.read(chatNotificationTargetProvider.notifier).open('c1');
      expect(container.read(chatNotificationTargetProvider), 'c1');
      container.read(chatNotificationTargetProvider.notifier).clear();
      expect(container.read(chatNotificationTargetProvider), isNull);
    });
  });
}
