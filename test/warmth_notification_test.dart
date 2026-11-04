import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/nudges/domain/nudge.dart';
import 'package:pathfinders/features/nudges/domain/warmth_notification.dart';

void main() {
  NudgePing incoming(NudgeWarmth warmth, String message) {
    return NudgePing(
      id: 'remote-1',
      circleId: 'c1',
      fromUserId: 'alex',
      fromName: '',
      targetId: 'u',
      warmth: warmth,
      message: message,
      sentAt: DateTime(2026, 11, 4, 12),
    );
  }

  test('title shows the warmth and the body keeps the personal message', () {
    final notification = WarmthNotification.fromPing(
      incoming(NudgeWarmth.kiss, 'Alex sent you a sweet kiss!'),
    );

    expect(notification.title, '😘 Kiss');
    expect(notification.body, 'Alex sent you a sweet kiss!');
  });

  test('every warmth keeps its own emoji and label in the title', () {
    for (final warmth in NudgeWarmth.values) {
      final notification = WarmthNotification.fromPing(
        incoming(warmth, warmth.messageFor('Alex')),
      );

      expect(notification.title, '${warmth.emoji} ${warmth.label}');
      expect(notification.body, warmth.messageFor('Alex'));
    }
  });

  test(
    'payload carries the circle, sender, and warmth key for tap routing',
    () {
      final notification = WarmthNotification.fromPing(
        incoming(NudgeWarmth.checkIn, 'Alex is checking in on you.'),
      );

      expect(jsonDecode(notification.payload), {
        'circle_id': 'c1',
        'sender_id': 'alex',
        'warmth': 'check_in',
      });
    },
  );

  test('notification ids stay in the positive int range Android expects', () {
    for (final warmth in NudgeWarmth.values) {
      final notification = WarmthNotification.fromPing(
        incoming(warmth, warmth.template),
      );

      expect(notification.id, isNonNegative);
    }
  });
}
