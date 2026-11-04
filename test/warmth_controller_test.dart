import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/nudges/application/nudge_providers.dart';
import 'package:pathfinders/features/nudges/domain/nudge.dart';
import 'package:pathfinders/features/nudges/domain/nudge_repository.dart';

class _FakeNudgeRepository implements NudgeRepository {
  final incoming = StreamController<NudgePing>.broadcast();
  final sent =
      <
        ({String senderId, String targetId, NudgeWarmth warmth, String message})
      >[];

  @override
  Future<void> send({
    required String senderId,
    required String targetId,
    required NudgeWarmth warmth,
    required String message,
  }) async {
    sent.add((
      senderId: senderId,
      targetId: targetId,
      warmth: warmth,
      message: message,
    ));
  }

  @override
  Stream<NudgePing> watchIncoming(String userId) => incoming.stream;
}

NudgePing _incoming({
  required String targetId,
  String message = 'Alex sent you a sweet kiss!',
}) {
  return NudgePing(
    id: 'remote-1',
    circleId: 'c1',
    fromUserId: 'alex',
    fromName: '',
    targetId: targetId,
    warmth: NudgeWarmth.kiss,
    message: message,
    sentAt: DateTime(2026, 11, 4, 12),
  );
}

void main() {
  late _FakeNudgeRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeNudgeRepository();
    container = ProviderContainer(
      overrides: [nudgeRepositoryProvider('c1').overrideWithValue(repository)],
    );
    container.listen(nudgeControllerProvider('c1', 'u'), (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await repository.incoming.close();
  });

  test(
    'sending writes the payload and reveals the sender confirmation',
    () async {
      await container
          .read(nudgeControllerProvider('c1', 'u').notifier)
          .send(
            senderId: 'u',
            senderName: 'Kaleab',
            targetId: 'hana',
            targetName: 'Hana',
            warmth: NudgeWarmth.kiss,
          );

      expect(repository.sent.single.targetId, 'hana');
      expect(repository.sent.single.warmth, NudgeWarmth.kiss);
      expect(repository.sent.single.message, 'Kaleab sent you a sweet kiss!');

      final ping = container.read(nudgeControllerProvider('c1', 'u'));
      expect(ping?.warmth, NudgeWarmth.kiss);
      expect(ping?.targetName, 'Hana');
      expect(ping?.message, 'Kaleab sent you a sweet kiss!');
    },
  );

  test('incoming warmth for this member is revealed verbatim', () async {
    repository.incoming.add(_incoming(targetId: 'u'));
    await Future<void>.delayed(Duration.zero);

    final ping = container.read(nudgeControllerProvider('c1', 'u'));
    expect(ping?.fromUserId, 'alex');
    expect(ping?.message, 'Alex sent you a sweet kiss!');
  });

  test('warmth addressed to someone else is ignored', () async {
    repository.incoming.add(_incoming(targetId: 'hana'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(nudgeControllerProvider('c1', 'u')), isNull);
  });
}
