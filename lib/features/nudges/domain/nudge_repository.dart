import 'nudge.dart';

/// Could not deliver a warmth action; [message] is safe to show as-is.
class NudgeFailure implements Exception {
  const NudgeFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class NudgeRepository {
  Future<void> send({
    required String senderId,
    required String targetId,
    required NudgeWarmth warmth,
    required String message,
  });

  /// Warmth sent to [userId] in this circle, oldest events first as they
  /// arrive.
  Stream<NudgePing> watchIncoming(String userId);
}
