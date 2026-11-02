import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/supabase_chat_repository.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';

part 'chat_providers.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref, String circleId) =>
    SupabaseChatRepository(
      ref.watch(supabaseClientProvider),
      circleId: circleId,
    );

@riverpod
Stream<List<ChatMessage>> circleMessages(Ref ref, String circleId) =>
    ref.watch(chatRepositoryProvider(circleId)).watchMessages();

/// The moment this device last looked at the thread, kept in memory so the
/// map's badge only counts messages that arrived while the chat was closed.
@Riverpod(keepAlive: true)
class ChatSeenController extends _$ChatSeenController {
  @override
  DateTime build(String circleId) => DateTime.now();

  void markSeen() {
    state = DateTime.now();
  }
}

typedef ChatUnreadQuery = ({String circleId, String userId});

@riverpod
int chatUnreadCount(Ref ref, ChatUnreadQuery query) {
  final lastSeen = ref.watch(chatSeenControllerProvider(query.circleId));
  final messages =
      ref.watch(circleMessagesProvider(query.circleId)).value ??
      const <ChatMessage>[];

  return countUnreadMessages(
    messages,
    lastSeen: lastSeen,
    currentUserId: query.userId,
  );
}

int countUnreadMessages(
  List<ChatMessage> messages, {
  required DateTime lastSeen,
  required String currentUserId,
}) {
  return messages
      .where(
        (message) =>
            message.senderId != currentUserId &&
            message.createdAt.isAfter(lastSeen),
      )
      .length;
}
