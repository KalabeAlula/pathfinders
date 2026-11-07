import 'chat_message.dart';

/// The circle's thread. Destination updates arrive from the backend trigger,
/// so this contract only exposes member-authored writes.
abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchMessages();

  Future<void> sendText({
    required String senderId,
    required String text,
    String? replyToId,
    List<String> mentionedUserIds = const [],
  });

  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
    String? replyToId,
  });

  /// Rewrites one of the caller's own text messages. The database stamps the
  /// edit time; the caller only supplies the new words and mentions.
  Future<void> editText({
    required String messageId,
    required String text,
    List<String> mentionedUserIds = const [],
  });

  /// Removes one of the caller's own text messages.
  Future<void> deleteMessage(String messageId);
}
