import 'dart:convert';

import 'chat_message.dart';

/// What the operating system renders when a message arrives while the app is
/// away from the screen.
class ChatNotification {
  const ChatNotification({
    required this.id,
    required this.circleId,
    required this.senderName,
    required this.title,
    required this.body,
    required this.payload,
  });

  factory ChatNotification.fromMessage({
    required ChatMessage message,
    required String circleId,
    required String circleName,
  }) {
    return ChatNotification(
      // Stable per message so a redelivered row replaces its own entry.
      id: message.id.hashCode & 0x7fffffff,
      circleId: circleId,
      senderName: message.senderName,
      title: '${message.senderName} • $circleName',
      body: chatNotificationBody(message),
      payload: jsonEncode({'kind': 'chat', 'circle_id': circleId}),
    );
  }

  /// Mirrors [ChatNotification.fromMessage] for messages that arrived as a
  /// cloud push, so both paths post the same grouped entry.
  factory ChatNotification.fromPush({
    required String messageId,
    required String circleId,
    required String senderName,
    required String title,
    required String body,
  }) {
    return ChatNotification(
      id: messageId.hashCode & 0x7fffffff,
      circleId: circleId,
      senderName: senderName,
      title: title,
      body: body,
      payload: jsonEncode({'kind': 'chat', 'circle_id': circleId}),
    );
  }

  final int id;
  final String circleId;
  final String senderName;
  final String title;
  final String body;

  /// Carried with the notification so a tap can open the right circle later.
  final String payload;

  static String groupKeyFor(String circleId) => 'chat-$circleId';

  static int summaryIdFor(String circleId) =>
      'chat-summary-$circleId'.hashCode & 0x7fffffff;
}

String chatNotificationBody(ChatMessage message) => switch (message.kind) {
  ChatMessageKind.text => message.text ?? '',
  ChatMessageKind.locationShare => '📍 Shared a location',
  ChatMessageKind.destinationUpdate => '📍 Updated the destination',
};

/// The circle a notification payload points at, or null for payloads this
/// feature does not own (warmth, or malformed data).
String? chatCircleFromPayload(String? payload) {
  if (payload == null) return null;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic> && decoded['kind'] == 'chat') {
      final circleId = decoded['circle_id'];
      if (circleId is String && circleId.isNotEmpty) return circleId;
    }
  } on FormatException {
    return null;
  }
  return null;
}
