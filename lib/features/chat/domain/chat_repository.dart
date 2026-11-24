import 'chat_message.dart';
import 'chat_poll.dart';

/// Who is writing, in the pieces the thread renders.
///
/// The thread already knows the sender's id; this lets a message be shown
/// locally before the server confirms it.
class ChatSender {
  const ChatSender({required this.displayName, required this.avatarColor});

  final String displayName;
  final int avatarColor;
}

/// The circle's thread. Destination updates arrive from the backend trigger,
/// so this contract only exposes member-authored writes.
abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchMessages();

  /// Forces an immediate re-fetch of the thread, bypassing the realtime
  /// debounce. Call this after the app returns to the foreground so any
  /// messages missed while the WebSocket was suspended are loaded.
  void forceRefresh();

  /// [localEcho] shows the message immediately; the server copy replaces it
  /// once the insert lands.
  Future<void> sendText({
    required String senderId,
    required String text,
    ChatMessage? replyTo,
    List<String> mentionedUserIds = const [],
    ChatSender? localEcho,
  });

  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  });

  /// Posts a Giphy rendition. The URL is validated against the allowed hosts
  /// before it reaches the database.
  Future<void> sendGif({
    required String senderId,
    required String url,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  });

  /// Posts a vote: the question plus 2-6 options, any of which may carry a
  /// place the crew can later head to.
  Future<void> createPoll({
    required String senderId,
    required String question,
    required List<ChatPollDraftOption> options,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  });

  /// Picks [optionId] on a poll. Tapping the option already chosen clears the
  /// vote, mirroring the database rule.
  Future<void> castVote({required String messageId, required String optionId});

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
