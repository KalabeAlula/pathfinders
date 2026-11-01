import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/memories_failure.dart';
import '../domain/memories_repository.dart';
import '../domain/memory_post.dart';

/// Reads and writes the memory feed for one circle.
///
/// Realtime changes are coalesced for 250 ms so a burst of inserts (e.g. two
/// members posting at once) still triggers a single refetch.
class SupabaseMemoriesRepository implements MemoriesRepository {
  SupabaseMemoriesRepository(this._client, {required this.circleId});

  final sb.SupabaseClient _client;
  final String circleId;

  static const _columns =
      'id, author_id, body, mood, place_label, voice_note_seconds, created_at';

  @override
  Stream<List<MemoryPost>> watchMemories() async* {
    final changes = StreamController<void>.broadcast();
    Timer? debounce;

    void scheduleRefresh() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 250), () {
        if (!changes.isClosed) changes.add(null);
      });
    }

    final channel = _client
        .channel('memories-changes-$circleId')
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'memories',
          callback: (_) => scheduleRefresh(),
        )
      ..subscribe();

    try {
      yield await _fetch();
      await for (final _ in changes.stream) {
        try {
          yield await _fetch();
        } catch (error) {
          // Keep showing the last good feed; the next event retries.
          developer.log(
            'Could not refresh the memory feed',
            name: 'pathfinders.memories',
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
  Future<void> addMemory({
    required String authorId,
    required String text,
    required MemoryMood mood,
    String? placeLabel,
    int? voiceNoteSeconds,
  }) async {
    final label = placeLabel?.trim();
    try {
      await _client.from('memories').insert({
        'circle_id': circleId,
        'author_id': authorId,
        'body': text.trim(),
        'mood': mood.name,
        if (label != null && label.isNotEmpty) 'place_label': label,
        'voice_note_seconds': ?voiceNoteSeconds,
      });
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback: 'Could not save that memory. Check your connection and try '
            'again.',
      );
    } on Exception {
      throw const MemoriesFailure(
        'Could not save that memory. Check your connection and try again.',
      );
    }
  }

  Future<List<MemoryPost>> _fetch() async {
    try {
      final rows = await _client
          .from('memories')
          .select(_columns)
          .eq('circle_id', circleId)
          .order('created_at', ascending: false)
          .limit(40);

      return [
        for (final row in rows)
          MemoryPost(
            id: row['id'] as String,
            authorId: row['author_id'] as String,
            text: row['body'] as String,
            mood: _mood(row['mood']),
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
            placeLabel: _optionalLabel(row['place_label']),
            voiceNoteSeconds: (row['voice_note_seconds'] as num?)?.toInt(),
          ),
      ];
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback: 'Could not reach your memories. Check your connection and '
            'try again.',
      );
    }
  }

  static MemoryMood _mood(Object? value) => MemoryMood.values.firstWhere(
        (mood) => mood.name == value,
        orElse: () => MemoryMood.cozy,
      );

  static String? _optionalLabel(Object? value) {
    if (value is! String) return null;
    final label = value.trim();
    return label.isEmpty ? null : label;
  }

  static MemoriesFailure _mapFailure(
    sb.PostgrestException error, {
    required String fallback,
  }) {
    final message = switch (error.code) {
      '23514' || '22001' => 'That memory is a little too long.',
      '42501' || 'PGRST301' => 'Sign in again to save this memory.',
      _ => null,
    };
    return MemoriesFailure(message ?? fallback, code: error.code);
  }
}
