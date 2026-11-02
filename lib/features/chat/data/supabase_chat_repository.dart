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
      'created_at, sender:profiles!chat_messages_sender_id_fkey'
      '(display_name, avatar_color)';

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
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _insert(senderId, {'kind': 'text', 'body': clean});
  }

  @override
  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
  }) async {
    await _insert(senderId, {
      'kind': 'location_share',
      'latitude': latitude,
      'longitude': longitude,
      if (placeLabel != null && placeLabel.trim().isNotEmpty)
        'place_label': placeLabel.trim(),
    });
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

      // The query is newest-first for the limit; the thread renders oldest
      // first like every other chat app.
      return [for (final row in rows.reversed) _message(row)];
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not reach the crew chat. Check your connection and '
            'try again.',
      );
    }
  }

  static ChatMessage _message(Map<String, dynamic> row) {
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
    );
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
      _ => null,
    };
    return ChatFailure(message ?? fallback, code: error.code);
  }
}
