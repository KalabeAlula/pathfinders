import 'chat_message.dart';

/// Combines the server's thread with messages that were echoed locally,
/// keeping one copy per id and ordering by send time.
///
/// A confirmed echo exists under the same id the client inserted, so the
/// server row replaces it here.
List<ChatMessage> mergeChatThread({
  required List<ChatMessage> thread,
  List<ChatMessage> optimistic = const [],
}) {
  final byId = <String, ChatMessage>{
    for (final message in thread) message.id: message,
  };
  for (final message in optimistic) {
    byId.putIfAbsent(message.id, () => message);
  }

  return byId.values.toList()..sort((a, b) {
    final order = a.createdAt.compareTo(b.createdAt);
    return order != 0 ? order : a.id.compareTo(b.id);
  });
}
