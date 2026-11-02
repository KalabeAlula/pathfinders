import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/chat_seen_store.dart';
import '../data/supabase_chat_repository.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';

part 'chat_providers.g.dart';

@riverpod
ChatSeenStore chatSeenStore(Ref ref) =>
    ChatSeenStore(ref.watch(sharedPreferencesProvider));

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref, String circleId) =>
    SupabaseChatRepository(
      ref.watch(supabaseClientProvider),
      circleId: circleId,
    );

@riverpod
Stream<List<ChatMessage>> circleMessages(Ref ref, String circleId) =>
    ref.watch(chatRepositoryProvider(circleId)).watchMessages();

/// The moment this device last looked at the thread, restored after restarts
/// so the map's badge only counts messages the member has not opened yet.
@Riverpod(keepAlive: true)
class ChatSeenController extends _$ChatSeenController {
  @override
  DateTime build(String circleId) =>
      ref.watch(chatSeenStoreProvider).read(circleId) ?? DateTime.now();

  void markSeen() {
    final seenAt = DateTime.now();
    state = seenAt;
    unawaited(ref.read(chatSeenStoreProvider).write(circleId, seenAt));
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
