import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/profile_details.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';

/// Reads and edits the signed-in member's row in `public.profiles`.
///
/// The realtime channel is what makes a name or avatar change visible to the
/// member's circles without a reload.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client, {required this.userId});

  final sb.SupabaseClient _client;
  final String userId;
  int _channelSequence = 0;

  @override
  Stream<ProfileDetails> watchProfile() async* {
    final changes = StreamController<void>.broadcast();
    final channel = _client
        .channel('profile-$userId-${_channelSequence++}')
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (_) {
            if (!changes.isClosed) changes.add(null);
          },
        )
        .subscribe();

    try {
      yield await _fetch();
      await for (final _ in changes.stream) {
        try {
          yield await _fetch();
        } catch (_) {
          // Keep the last good profile visible; the next event retries.
        }
      }
    } finally {
      await changes.close();
      await _client.removeChannel(channel);
    }
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _client
          .from('profiles')
          .update({'display_name': displayName})
          .eq('id', userId);
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> updateAvatar(String avatarId) async {
    try {
      await _client
          .from('profiles')
          .update({'avatar_id': avatarId})
          .eq('id', userId);
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  Future<ProfileDetails> _fetch() async {
    try {
      final row = await _client
          .from('profiles')
          .select('id, display_name, avatar_id, created_at')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        throw const ProfileFailure('Your profile is not ready yet.');
      }
      return ProfileDetails(
        userId: row['id'] as String,
        displayName: _displayName(row['display_name']),
        avatarId: _avatarId(row['avatar_id']),
        createdAt:
            DateTime.tryParse('${row['created_at']}')?.toLocal() ??
            DateTime.now(),
      );
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  static String _displayName(Object? value) {
    final name = value is String ? value.trim() : '';
    return name.isEmpty ? 'Pathfinder' : name;
  }

  static String _avatarId(Object? value) {
    final id = value is String ? value.trim() : '';
    return id.isEmpty ? 'avatar_wolf' : id;
  }

  static ProfileFailure _mapFailure(sb.PostgrestException error) {
    final message = switch (error.code) {
      '23514' => 'That name or avatar is not available.',
      '42501' => 'Sign in again to update your profile.',
      _ => null,
    };
    return ProfileFailure(
      message ??
          'Could not save your profile. Check your connection and try again.',
    );
  }
}
