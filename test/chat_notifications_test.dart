import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/application/app_visibility.dart';
import 'package:pathfinders/features/chat/application/chat_notification_providers.dart';
import 'package:pathfinders/features/chat/application/chat_providers.dart';
import 'package:pathfinders/features/chat/domain/chat_message.dart';
import 'package:pathfinders/features/chat/domain/chat_notification.dart';
import 'package:pathfinders/features/chat/domain/chat_notifier.dart';
import 'package:pathfinders/features/chat/domain/chat_repository.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/domain/circle_summary.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';

class _FakeChatRepository implements ChatRepository {
  final messages = StreamController<List<ChatMessage>>.broadcast();

  @override
  Stream<List<ChatMessage>> watchMessages() => messages.stream;

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

class _FakeChatNotifier implements ChatNotifier {
  int permissionRequests = 0;
  final shown = <ChatNotification>[];
  final cleared = <String>[];

  @override
  Future<void> ensurePermission() async {
    permissionRequests++;
  }

  @override
  Future<void> show(
    ChatNotification notification, {
    required String circleName,
  }) async {
    shown.add(notification);
  }

  @override
  Future<void> clearCircle(String circleId) async {
    cleared.add(circleId);
  }
}

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

CircleSummary _circle({String id = 'c1', String name = 'Simien Pair'}) {
  return CircleSummary(
    id: id,
    name: name,
    type: GroupType.couple,
    memberCount: 2,
    createdAt: DateTime(2026, 11, 1),
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

    test('ignores payloads that are not chat taps', () {
      expect(chatCircleFromPayload(null), isNull);
      expect(chatCircleFromPayload('not json'), isNull);
      expect(
        chatCircleFromPayload(jsonEncode({'circle_id': 'c1'})),
        isNull,
      );
      expect(
        chatCircleFromPayload(jsonEncode({'kind': 'warmth', 'circle_id': 'c1'})),
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

  group('ChatNotificationWatcher', () {
    late _FakeChatRepository repository;
    late _FakeChatNotifier notifier;
    late AppVisibility visibility;
    late ProviderContainer container;

    Future<void> settle() => pumpEventQueue(times: 20);

    setUp(() {
      repository = _FakeChatRepository();
      notifier = _FakeChatNotifier();
      visibility = AppVisibility();
      container = ProviderContainer(
        overrides: [
          circlesProvider('u').overrideWith(
            (_) => Stream.value([
              _circle(),
              _circle(id: 'c2', name: 'Bole Crew'),
            ]),
          ),
          chatRepositoryProvider('c1').overrideWithValue(repository),
          chatRepositoryProvider('c2').overrideWithValue(_FakeChatRepository()),
          chatNotificationsProvider.overrideWithValue(notifier),
          appVisibilityProvider.overrideWithValue(visibility),
        ],
      );
      container.listen(chatNotificationWatcherProvider('u'), (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await repository.messages.close();
    });

    test('asks for notification permission once the shell starts', () async {
      await settle();
      expect(notifier.permissionRequests, greaterThanOrEqualTo(1));
    });

    test('does not notify for the history it starts with', () async {
      repository.messages.add([_message(id: 'm1', senderId: 'hana')]);
      await settle();

      expect(notifier.shown, isEmpty);
    });

    test('notifies only for messages that arrive while backgrounded', () async {
      final history = [_message(id: 'm1', senderId: 'hana')];
      repository.messages.add(history);
      await settle();

      repository.messages.add([
        ...history,
        _message(id: 'm2', senderId: 'hana', text: 'On my way'),
      ]);
      await settle();
      expect(notifier.shown, isEmpty, reason: 'still in the foreground');

      visibility.update(AppLifecycleState.paused);
      repository.messages.add([
        ...history,
        _message(id: 'm2', senderId: 'hana', text: 'On my way'),
        _message(id: 'm3', senderId: 'hana', text: 'Two minutes!'),
      ]);
      await settle();

      expect(notifier.shown.map((entry) => entry.body), ['Two minutes!']);
      expect(notifier.shown.single.title, 'Hana Bekele • Simien Pair');
      expect(notifier.shown.single.circleId, 'c1');
    });

    test('never notifies the sender about their own message', () async {
      final history = [_message(id: 'm1', senderId: 'hana')];
      repository.messages.add(history);
      await settle();
      visibility.update(AppLifecycleState.paused);

      repository.messages.add([
        ...history,
        _message(id: 'm2', senderId: 'u', senderName: 'Me', text: 'Hey!'),
      ]);
      await settle();

      expect(notifier.shown, isEmpty);
    });

    test('skips destination updates', () async {
      final history = [_message(id: 'm1', senderId: 'hana')];
      repository.messages.add(history);
      await settle();
      visibility.update(AppLifecycleState.paused);

      repository.messages.add([
        ...history,
        _message(
          id: 'm2',
          senderId: 'hana',
          kind: ChatMessageKind.destinationUpdate,
        ),
      ]);
      await settle();

      expect(notifier.shown, isEmpty);
    });
  });

  group('ChatNotificationTarget', () {
    test('holds a tapped circle until the shell consumes it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(chatNotificationTargetProvider), isNull);
      container
          .read(chatNotificationTargetProvider.notifier)
          .open('c1');
      expect(container.read(chatNotificationTargetProvider), 'c1');
      container
          .read(chatNotificationTargetProvider.notifier)
          .clear();
      expect(container.read(chatNotificationTargetProvider), isNull);
    });
  });
}
