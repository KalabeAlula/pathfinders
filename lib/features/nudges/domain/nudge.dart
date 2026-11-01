enum NudgeKind { thinkingOfYou, onMyWay, needYou }

class NudgePing {
  const NudgePing({
    required this.id,
    required this.fromUserId,
    required this.recipientIds,
    required this.kind,
    required this.sentAt,
  });

  final String id;
  final String fromUserId;
  final List<String> recipientIds;
  final NudgeKind kind;
  final DateTime sentAt;

  bool get isGroupNudge => recipientIds.length > 1;
}
