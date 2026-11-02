import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/memories_failure.dart';
import '../domain/memories_repository.dart';
import '../domain/memory_photo.dart';
import '../domain/memory_post.dart';
import 'memories_cache.dart';

/// Reads and writes the memory feed for one circle.
///
/// Realtime changes are coalesced for 250 ms so a burst of inserts (e.g. two
/// members posting at once) still triggers a single refetch.
class SupabaseMemoriesRepository implements MemoriesRepository {
  SupabaseMemoriesRepository(
    this._client, {
    required this.circleId,
    this.cache,
  });

  final sb.SupabaseClient _client;
  final MemoriesCache? cache;
  final String circleId;

  static const _bucket = 'memories';

  static const _columns =
      'id, author_id, body, mood, place_label, voice_note_seconds, photo_path, '
      'created_at';

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

    final channel =
        _client
            .channel('memories-changes-$circleId')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'memories',
              callback: (_) => scheduleRefresh(),
            )
          ..subscribe();

    try {
      final cached = cache?.read();
      if (cached != null) yield cached;

      try {
        yield await _fetchAndCache();
      } catch (error) {
        if (cached == null) rethrow;
        // The cached feed is still worth showing; realtime may recover.
        developer.log(
          'Could not refresh the memory feed',
          name: 'pathfinders.memories',
          error: error,
        );
      }

      await for (final _ in changes.stream) {
        try {
          yield await _fetchAndCache();
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
    MemoryPhotoDraft? photo,
  }) async {
    final label = placeLabel?.trim();
    final body = text.trim();
    final photoPath = photo == null
        ? null
        : await _uploadPhoto(authorId: authorId, photo: photo);

    try {
      await _client.from('memories').insert({
        'circle_id': circleId,
        'author_id': authorId,
        'body': ?(body.isEmpty ? null : body),
        'mood': mood.name,
        if (label != null && label.isNotEmpty) 'place_label': label,
        'voice_note_seconds': ?voiceNoteSeconds,
        'photo_path': ?photoPath,
      });
    } on sb.PostgrestException catch (error) {
      await _discardPhoto(photoPath);
      throw _mapFailure(
        error,
        fallback:
            'Could not save that memory. Check your connection and try '
            'again.',
      );
    } on Exception {
      await _discardPhoto(photoPath);
      throw const MemoriesFailure(
        'Could not save that memory. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> deleteMemory(String memoryId, {String? photoPath}) async {
    try {
      await _client.from('memories').delete().eq('id', memoryId);
    } on sb.PostgrestException catch (error) {
      final message = switch (error.code) {
        '42501' => 'You can only delete memories you added.',
        'PGRST301' => 'Sign in again to delete this memory.',
        _ => null,
      };
      throw MemoriesFailure(
        message ??
            'Could not delete that memory. Check your connection and try '
                'again.',
        code: error.code,
      );
    } on Exception {
      throw const MemoriesFailure(
        'Could not delete that memory. Check your connection and try again.',
      );
    }

    if (photoPath != null) {
      try {
        await _client.storage.from(_bucket).remove([photoPath]);
      } on Exception {
        developer.log(
          'The memory was deleted but its photo was not',
          name: 'pathfinders.memories',
        );
      }
    }
  }

  Future<String> _uploadPhoto({
    required String authorId,
    required MemoryPhotoDraft photo,
  }) async {
    if (photo.bytes.isEmpty) {
      throw const MemoriesFailure('That photo looks empty. Try another one.');
    }
    if (photo.bytes.length > MemoryPhotoDraft.maxBytes) {
      throw const MemoriesFailure(
        'That photo is a little too large. Try a smaller one.',
      );
    }

    final path = '$circleId/$authorId/${_photoName(photo.extension)}';
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            photo.bytes,
            fileOptions: sb.FileOptions(contentType: photo.contentType),
          );
      return path;
    } on sb.StorageException catch (error) {
      throw _mapStorageFailure(error);
    } on Exception {
      throw const MemoriesFailure(
        'Could not upload that photo. Check your connection and try again.',
      );
    }
  }

  /// Removes an uploaded object when the memory row could not be written.
  Future<void> _discardPhoto(String? path) async {
    if (path == null) return;
    try {
      await _client.storage.from(_bucket).remove([path]);
    } on Exception {
      // Best effort: never mask the failure the caller needs to see.
    }
  }

  static String _photoName(String extension) {
    final random = Random.secure();
    final stem = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '$stem.$extension';
  }

  Future<List<MemoryPost>> _fetchAndCache() async {
    final memories = await _fetch();
    try {
      await cache?.write(memories);
    } on Exception {
      // A failed cache write must not hide a fresh feed.
    }
    return memories;
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
            text: (row['body'] as String?) ?? '',
            mood: _mood(row['mood']),
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
            placeLabel: _optionalText(row['place_label']),
            voiceNoteSeconds: (row['voice_note_seconds'] as num?)?.toInt(),
            photoPath: _optionalText(row['photo_path']),
          ),
      ];
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not reach your memories. Check your connection and '
            'try again.',
      );
    }
  }

  static MemoryMood _mood(Object? value) => MemoryMood.values.firstWhere(
    (mood) => mood.name == value,
    orElse: () => MemoryMood.cozy,
  );

  static String? _optionalText(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static MemoriesFailure _mapStorageFailure(sb.StorageException error) {
    final message = switch (error.statusCode) {
      '413' => 'That photo is a little too large. Try a smaller one.',
      '401' || '403' => 'Sign in again to add photos.',
      '400' => 'That photo type is not supported.',
      _ => null,
    };
    return MemoriesFailure(
      message ??
          'Could not upload that photo. Check your connection and try again.',
      code: error.statusCode,
    );
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
