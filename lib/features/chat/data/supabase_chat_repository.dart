import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/chat_failure.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';

/// Reads and writes the thread for one circle.
///
/// Realtime events are coalesced for 250 ms so a burst of messages still
/// triggers a single refetch instead of one per row.
class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client, {required this.circleId});

  final sb.SupabaseClient _client;
  final String circleId;

  static const _columns =
      'id, sender_id, kind, body, latitude, longitude, place_label, '
      'created_at, mentioned_user_ids, edited_at, reply_to_id, '
      'sender:profiles!chat_messages_sender_id_fkey'
      '(display_name, avatar_color)';

  static const _replyColumns =
      'id, sender_id, kind, body, place_label, '
      'sender:profiles!chat_messages_sender_id_fkey(display_name)';

  @override
  Stream<List<ChatMessage>> watchMessages() async* {
    final changes = StreamController<void>.broadcast();
    Timer? debounce;

    void scheduleRefresh() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 250), () {
        if (!changes.isClosed) changes.add(null);
      });
    }

    final channel =
        _client
            .channel('chat-changes-$circleId')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'chat_messages',
              filter: sb.PostgresChangeFilter(
                type: sb.PostgresChangeFilterType.eq,
                column: 'circle_id',
                value: circleId,
              ),
              callback: (_) => scheduleRefresh(),
            )
          ..subscribe();

    try {
      yield await _fetch();
      await for (final _ in changes.stream) {
        try {
          yield await _fetch();
        } catch (error) {
          // Keep showing the last good thread; the next event retries.
          developer.log(
            'Could not refresh the chat thread',
            name: 'pathfinders.chat',
            error: error,
          );
        }
      }
    } finally {
      debounce?.cancel();
      await changes.close();
      await _client.removeChannel(channel);
    }
  }

  @override
  Future<void> sendText({
    required String senderId,
    required String text,
    String? replyToId,
    List<String> mentionedUserIds = const [],
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _insert(senderId, {
      'kind': 'text',
      'body': clean,
      'reply_to_id': ?replyToId,
      if (mentionedUserIds.isNotEmpty) 'mentioned_user_ids': mentionedUserIds,
    });
  }

  @override
  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
    String? replyToId,
  }) async {
    await _insert(senderId, {
      'kind': 'location_share',
      'latitude': latitude,
      'longitude': longitude,
      if (placeLabel != null && placeLabel.trim().isNotEmpty)
        'place_label': placeLabel.trim(),
      'reply_to_id': ?replyToId,
    });
  }

  @override
  Future<void> editText({
    required String messageId,
    required String text,
    List<String> mentionedUserIds = const [],
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      throw const ChatFailure('Write something before saving the edit.');
    }

    final List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('chat_messages')
          .update({'body': clean, 'mentioned_user_ids': mentionedUserIds})
          .eq('id', messageId)
          .select('id');
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not save that edit. Check your connection and try again.',
      );
    } on Exception {
      throw const ChatFailure(
        'Could not save that edit. Check your connection and try again.',
      );
    }

    // RLS quietly matches nothing when the message is not the caller's.
    if (rows.isEmpty) {
      throw const ChatFailure('Only the sender can edit a message.');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('chat_messages')
          .delete()
          .eq('id', messageId)
          .select('id');
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not delete that message. Check your connection and try '
            'again.',
      );
    } on Exception {
      throw const ChatFailure(
        'Could not delete that message. Check your connection and try again.',
      );
    }

    if (rows.isEmpty) {
      throw const ChatFailure('Only the sender can delete a message.');
    }
  }

  Future<void> _insert(String senderId, Map<String, Object?> fields) async {
    try {
      await _client.from('chat_messages').insert({
        'circle_id': circleId,
        'sender_id': senderId,
        ...fields,
      });
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not send that message. Check your connection and try '
            'again.',
      );
    } on Exception {
      throw const ChatFailure(
        'Could not send that message. Check your connection and try again.',
      );
    }
  }

  Future<List<ChatMessage>> _fetch() async {
    try {
      final rows = await _client
          .from('chat_messages')
          .select(_columns)
          .eq('circle_id', circleId)
          .order('created_at', ascending: false)
          .limit(100);

      // A self-join embed is ambiguous over PostgREST, so quoted parents are
      // fetched by id. This also lets a reply quote a message that has aged
      // out of the rolling 100-message window.
      final replyIds = <String>{
        for (final row in rows)
          if (row['reply_to_id'] case final String id) id,
      };
      final parents = replyIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
                .from('chat_messages')
                .select(_replyColumns)
                .inFilter('id', replyIds.toList());
      final parentsById = {
        for (final parent in parents) parent['id'] as String: parent,
      };

      // The query is newest-first for the limit; the thread renders oldest
      // first like every other chat app.
      return [for (final row in rows.reversed) _message(row, parentsById)];
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not reach the crew chat. Check your connection and '
            'try again.',
      );
    }
  }

  static ChatMessage _message(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> parentsById,
  ) {
    final sender = switch (row['sender']) {
      final Map<String, dynamic> profile => profile,
      final List<dynamic> profiles when profiles.isNotEmpty =>
        profiles.first is Map<String, dynamic>
            ? profiles.first as Map<String, dynamic>
            : const <String, dynamic>{},
      _ => const <String, dynamic>{},
    };

    return ChatMessage(
      id: row['id'] as String,
      senderId: row['sender_id'] as String,
      senderName: _text(sender['display_name']) ?? 'A member',
      senderAvatarColor:
          (sender['avatar_color'] as num?)?.toInt() ?? 0xFF6F9E62,
      kind: _kind(row['kind']),
      text: _text(row['body']),
      placeLabel: _text(row['place_label']),
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      replyTo: switch (row['reply_to_id']) {
        final String replyId => _reply(parentsById[replyId]),
        _ => null,
      },
      mentionedUserIds:
          (row['mentioned_user_ids'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      editedAt: _timestamp(row['edited_at']),
    );
  }

  static ChatMessageReply? _reply(Map<String, dynamic>? reply) {
    final id = reply?['id'];
    if (reply == null || id is! String) return null;

    final sender = switch (reply['sender']) {
      final Map<String, dynamic> profile => profile,
      final List<dynamic> profiles when profiles.isNotEmpty =>
        profiles.first is Map<String, dynamic>
            ? profiles.first as Map<String, dynamic>
            : const <String, dynamic>{},
      _ => const <String, dynamic>{},
    };
    final kind = reply['kind'];
    final place = _text(reply['place_label']);

    return ChatMessageReply(
      id: id,
      senderId: reply['sender_id'] as String? ?? '',
      senderName: _text(sender['display_name']) ?? 'A member',
      text: switch (kind) {
        'text' => _text(reply['body']),
        'destination_update' =>
          place == null
              ? 'Updated the destination'
              : 'Updated the destination to $place',
        _ => null,
      },
      mediaPreview: kind == 'location_share'
          ? place ?? 'Shared location'
          : null,
    );
  }

  static DateTime? _timestamp(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static ChatMessageKind _kind(Object? value) => switch (value) {
    'location_share' => ChatMessageKind.locationShare,
    'destination_update' => ChatMessageKind.destinationUpdate,
    _ => ChatMessageKind.text,
  };

  static String? _text(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static ChatFailure _mapFailure(
    sb.PostgrestException error, {
    required String fallback,
  }) {
    final message = switch (error.code) {
      '23514' || '22001' => 'That message is a little too long.',
      '42501' || 'PGRST301' => 'Sign in again to send messages.',
      '23503' || 'P0001' => 'That message is no longer in this thread.',
      _ => null,
    };
    return ChatFailure(message ?? fallback, code: error.code);
  }
}
