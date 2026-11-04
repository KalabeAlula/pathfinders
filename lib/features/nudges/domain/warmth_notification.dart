import 'dart:convert';

import 'nudge.dart';

/// What the operating system renders when warmth arrives while the app is
/// away from the screen.
///
/// The body is the already-personalised [NudgePing.message], so the sender's
/// name reads the same in the notification shade as it does in the in-app
/// banner.
class WarmthNotification {
  const WarmthNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  factory WarmthNotification.fromPing(NudgePing ping) {
    return WarmthNotification(
      // Android replaces a notification with the same id, so the send time
      // doubles as a cheap, mostly unique handle.
      id: ping.sentAt.millisecondsSinceEpoch & 0x7fffffff,
      title: '${ping.warmth.emoji} ${ping.warmth.label}',
      body: ping.message,
      payload: jsonEncode({
        'circle_id': ping.circleId,
        'sender_id': ping.fromUserId,
        'warmth': ping.warmth.key,
      }),
    );
  }

  final int id;
  final String title;
  final String body;

  /// Carried with the notification so a tap can open the right circle later.
  final String payload;
}
