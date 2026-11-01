import '../domain/nudge.dart';
import '../domain/nudge_repository.dart';

class MockNudgeRepository implements NudgeRepository {
  @override
  Future<NudgePing> send({
    required String fromUserId,
    required List<String> recipientIds,
    required NudgeKind kind,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final sentAt = DateTime.now();
    return NudgePing(
      id: 'nudge_${sentAt.microsecondsSinceEpoch}',
      fromUserId: fromUserId,
      recipientIds: List.unmodifiable(recipientIds),
      kind: kind,
      sentAt: sentAt,
    );
  }
}
