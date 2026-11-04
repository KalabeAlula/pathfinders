import '../../circle/domain/group_type.dart';

/// One kind of warmth a group can share.
///
/// [template] is phrased from the recipient's point of view; the `{name}`
/// placeholder is replaced with the sender's first name. [key] is what the
/// database stores, so renaming a label never rewrites history.
enum NudgeWarmth {
  kiss(
    type: GroupType.couple,
    key: 'kiss',
    label: 'Kiss',
    emoji: '😘',
    template: '{name} sent you a sweet kiss!',
  ),
  hug(
    type: GroupType.couple,
    key: 'hug',
    label: 'Hug',
    emoji: '🤗',
    template: '{name} is wrapping you in a warm hug!',
  ),
  coupleThinkingOfYou(
    type: GroupType.couple,
    key: 'thinking_of_you',
    label: 'Thinking of you',
    emoji: '💭',
    template: '{name} is thinking of you.',
  ),
  loveYou(
    type: GroupType.couple,
    key: 'love_you',
    label: 'Love you',
    emoji: '❤️',
    template: '{name} sent you love.',
  ),
  highFive(
    type: GroupType.friends,
    key: 'high_five',
    label: 'High five',
    emoji: '🙌',
    template: '{name} sent a high five!',
  ),
  fistBump(
    type: GroupType.friends,
    key: 'fist_bump',
    label: 'Fist bump',
    emoji: '👊',
    template: '{name} gave you a fist bump!',
  ),
  wave(
    type: GroupType.friends,
    key: 'wave',
    label: 'Wave',
    emoji: '👋',
    template: '{name} is waving at you!',
  ),
  whereYouAt(
    type: GroupType.friends,
    key: 'where_you_at',
    label: 'Where you at?',
    emoji: '📍',
    template: "{name} is checking where you're at!",
  ),
  warmHug(
    type: GroupType.family,
    key: 'warm_hug',
    label: 'Warm hug',
    emoji: '🤗',
    template: '{name} sent a warm family hug!',
  ),
  checkIn(
    type: GroupType.family,
    key: 'check_in',
    label: 'Check-in',
    emoji: '🏡',
    template: '{name} is checking in on you.',
  ),
  familyLove(
    type: GroupType.family,
    key: 'family_love',
    label: 'Thinking of you',
    emoji: '❤️',
    template: '{name} sent some love.',
  );

  const NudgeWarmth({
    required this.type,
    required this.key,
    required this.label,
    required this.emoji,
    required this.template,
  });

  final GroupType type;
  final String key;
  final String label;
  final String emoji;
  final String template;

  String messageFor(String senderFirstName) =>
      template.replaceFirst('{name}', senderFirstName);

  static List<NudgeWarmth> optionsFor(GroupType type) => [
    for (final warmth in values)
      if (warmth.type == type) warmth,
  ];

  /// Quick taps send the first option, so it doubles as the group's favourite.
  static NudgeWarmth defaultFor(GroupType type) => optionsFor(type).first;

  static NudgeWarmth fromKey(Object? key) {
    for (final warmth in values) {
      if (warmth.key == key) return warmth;
    }
    return defaultFor(GroupType.fallback);
  }
}

/// One delivered warmth action.
///
/// [targetName] is only known on the sending device, where the confirmation
/// banner names the recipient. Incoming pings rely on [message].
class NudgePing {
  const NudgePing({
    required this.id,
    required this.circleId,
    required this.fromUserId,
    required this.fromName,
    required this.targetId,
    required this.warmth,
    required this.message,
    required this.sentAt,
    this.targetName,
  });

  final String id;
  final String circleId;
  final String fromUserId;
  final String fromName;
  final String targetId;
  final String? targetName;
  final NudgeWarmth warmth;
  final String message;
  final DateTime sentAt;

  /// Shape of the row that is written to the nudges table and broadcast to
  /// the recipient.
  Map<String, Object?> toPayload() => {
    'sender_id': fromUserId,
    'target_id': targetId,
    'warmth_type': warmth.key,
    'emoji': warmth.emoji,
    'message': message,
  };
}
