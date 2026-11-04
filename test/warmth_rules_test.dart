import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/nudges/domain/nudge.dart';

void main() {
  group('warmth catalogue', () {
    test('couples get kisses, hugs, and love', () {
      final options = NudgeWarmth.optionsFor(GroupType.couple);

      expect(options.map((warmth) => warmth.key), [
        'kiss',
        'hug',
        'thinking_of_you',
        'love_you',
      ]);
      expect(NudgeWarmth.defaultFor(GroupType.couple), NudgeWarmth.kiss);
    });

    test('friends get playful signals instead of romance', () {
      final options = NudgeWarmth.optionsFor(GroupType.friends);

      expect(options.map((warmth) => warmth.key), [
        'high_five',
        'fist_bump',
        'wave',
        'where_you_at',
      ]);
      expect(NudgeWarmth.defaultFor(GroupType.friends), NudgeWarmth.highFive);
      expect(options.map((warmth) => warmth.label), isNot(contains('Kiss')));
    });

    test('families get warm, checking-in signals', () {
      final options = NudgeWarmth.optionsFor(GroupType.family);

      expect(options.map((warmth) => warmth.key), [
        'warm_hug',
        'check_in',
        'family_love',
      ]);
      expect(NudgeWarmth.defaultFor(GroupType.family), NudgeWarmth.warmHug);
    });

    test('every option knows its emoji and personalized message', () {
      expect(NudgeWarmth.kiss.emoji, '😘');
      expect(
        NudgeWarmth.kiss.messageFor('Alex'),
        'Alex sent you a sweet kiss!',
      );
      expect(
        NudgeWarmth.whereYouAt.messageFor('Alex'),
        "Alex is checking where you're at!",
      );
      expect(
        NudgeWarmth.warmHug.messageFor('Alex'),
        'Alex sent a warm family hug!',
      );
      expect(NudgeWarmth.familyLove.messageFor('Alex'), 'Alex sent some love.');
    });

    test('database keys round-trip, unknown keys fall back', () {
      for (final warmth in NudgeWarmth.values) {
        expect(NudgeWarmth.fromKey(warmth.key), warmth);
      }
      expect(
        NudgeWarmth.fromKey('retired_action'),
        NudgeWarmth.defaultFor(GroupType.fallback),
      );
    });
  });

  group('nudge payload', () {
    test('carries the sender, target, warmth type, emoji, and message', () {
      final sentAt = DateTime(2026, 11, 4, 12);
      final ping = NudgePing(
        id: 'n1',
        circleId: 'c1',
        fromUserId: 'sender',
        fromName: 'Kaleab',
        targetId: 'target',
        targetName: 'Hana',
        warmth: NudgeWarmth.kiss,
        message: NudgeWarmth.kiss.messageFor('Kaleab'),
        sentAt: sentAt,
      );

      expect(ping.toPayload(), {
        'sender_id': 'sender',
        'target_id': 'target',
        'warmth_type': 'kiss',
        'emoji': '😘',
        'message': 'Kaleab sent you a sweet kiss!',
      });
    });
  });
}
