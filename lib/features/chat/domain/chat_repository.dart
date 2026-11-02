import 'chat_message.dart';

/// The circle's thread. Destination updates arrive from the backend trigger,
/// so this contract only exposes member-authored writes.
abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchMessages();

  Future<void> sendText({required String senderId, required String text});

  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
  });
}
