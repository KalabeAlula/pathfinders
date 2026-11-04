import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/nudge.dart';
import '../domain/nudge_repository.dart';

/// Writes warmth rows and watches the signed-in member's inbox.
class SupabaseNudgeRepository implements NudgeRepository {
  SupabaseNudgeRepository(this._client, {required this.circleId});

  final sb.SupabaseClient _client;
  final String circleId;

  @override
  Future<void> send({
    required String senderId,
    required String targetId,
    required NudgeWarmth warmth,
    required String message,
  }) async {
    try {
      await _client.from('nudges').insert({
        'circle_id': circleId,
        'sender_id': senderId,
        'target_id': targetId,
        'warmth_type': warmth.key,
        'emoji': warmth.emoji,
        'message': message,
      });
    } on sb.PostgrestException {
      throw const NudgeFailure('Could not send that warmth. Try again.');
    } on Exception {
      throw const NudgeFailure('Could not send that warmth. Try again.');
    }
  }

  @override
  Stream<NudgePing> watchIncoming(String userId) async* {
    final events = StreamController<NudgePing>.broadcast();
    final channel =
        _client
            .channel('nudges-$circleId-$userId')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.insert,
              schema: 'public',
              table: 'nudges',
              filter: sb.PostgresChangeFilter(
                type: sb.PostgresChangeFilterType.eq,
                column: 'target_id',
                value: userId,
              ),
              callback: (payload) {
                if (events.isClosed) return;
                events.add(_fromRow(payload.newRecord));
              },
            )
          ..subscribe();

    try {
      yield* events.stream;
    } finally {
      await events.close();
      await _client.removeChannel(channel);
    }
  }

  NudgePing _fromRow(Map<String, dynamic> row) {
    final warmth = NudgeWarmth.fromKey(row['warmth_type']);
    final message = (row['message'] as String?)?.trim();
    return NudgePing(
      id: '${row['id']}',
      circleId: row['circle_id'] as String? ?? circleId,
      fromUserId: '${row['sender_id']}',
      fromName: '',
      targetId: '${row['target_id']}',
      warmth: warmth,
      message: message == null || message.isEmpty
          ? warmth.messageFor('Someone')
          : message,
      sentAt:
          DateTime.tryParse('${row['created_at']}')?.toLocal() ??
          DateTime.now(),
    );
  }
}
