import 'nudge.dart';

abstract interface class NudgeRepository {
  Future<NudgePing> send({
    required String fromUserId,
    required List<String> recipientIds,
    required NudgeKind kind,
  });
}
