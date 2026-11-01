import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../location/data/member_status_mapper.dart';
import '../domain/circle.dart';
import '../domain/circle_failure.dart';
import '../domain/circle_member.dart';
import '../domain/circle_repository.dart';
import '../domain/circle_snapshot.dart';
import '../domain/user_profile.dart';

/// Reads the signed-in user's circle and refreshes it on realtime changes.
///
/// Status rows arrive already masked by the database, so a paused member has
/// no coordinates and an approximate member only has a coarse point.
class SupabaseCircleRepository implements CircleRepository {
  SupabaseCircleRepository(
    this._client, {
    required this.userId,
  });

  final sb.SupabaseClient _client;
  final String userId;

  @override
  Stream<CircleSnapshot?> watchCircle() async* {
    final changes = StreamController<void>.broadcast();
    Timer? debounce;

    void scheduleRefresh() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 250), () {
        if (!changes.isClosed) changes.add(null);
      });
    }

    final channel = _client
        .channel('circle-changes-$userId')
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'circle_members',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'circles',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'member_status',
          callback: (_) => scheduleRefresh(),
        )
      ..subscribe();

    try {
      yield await _fetch();
      await for (final _ in changes.stream) {
        try {
          yield await _fetch();
        } catch (error) {
          // Keep showing the last good snapshot; the next event retries.
          developer.log(
            'Could not refresh the circle snapshot',
            name: 'pathfinders.circle',
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
  Future<void> createCircle({required String name}) => _runRpc(
        () => _client.rpc(
          'create_circle',
          params: {'p_name': name.trim()},
        ),
      );

  @override
  Future<void> joinCircle({required String code}) => _runRpc(
        () => _client.rpc(
          'join_circle',
          params: {'p_code': code.trim().toUpperCase()},
        ),
      );

  Future<void> _runRpc(Future<Object?> Function() call) async {
    try {
      await call();
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  Future<CircleSnapshot?> _fetch() async {
    try {
      final membership = await _client
          .from('circle_members')
          .select('circle_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (membership == null) return null;

      final circleId = membership['circle_id'] as String;

      final circleRow = await _client
          .from('circles')
          .select('id, name, invite_code, created_at')
          .eq('id', circleId)
          .single();

      final membershipRows = await _client
          .from('circle_members')
          .select('user_id')
          .eq('circle_id', circleId)
          .order('joined_at', ascending: true);

      final orderedIds = [
        for (final row in membershipRows) row['user_id'] as String,
      ];

      final profileRows = orderedIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
              .from('profiles')
              .select('id, display_name, avatar_color')
              .inFilter('id', orderedIds);

      final profiles = {
        for (final row in profileRows)
          row['id'] as String: UserProfile(
            id: row['id'] as String,
            displayName: _displayName(row['display_name']),
            avatarColor: (row['avatar_color'] as num?)?.toInt() ?? 0xFFB86B4F,
          ),
      };

      final statusRows = orderedIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
              .from('member_status')
              .select(
                'user_id, latitude, longitude, accuracy_meters, '
                'battery_percent, is_charging, speed_kph, privacy_mode, '
                'arrived_at, updated_at',
              )
              .inFilter('user_id', orderedIds);

      final now = DateTime.now();
      final statuses = {
        for (final row in statusRows)
          row['user_id'] as String: MemberStatusMapper.fromRow(row, now: now),
      };

      final members = <CircleMember>[
        for (final id in orderedIds)
          if (profiles[id] case final profile?)
            CircleMember(profile: profile, status: statuses[profile.id]),
      ];

      return CircleSnapshot(
        circle: Circle(
          id: circleRow['id'] as String,
          name: circleRow['name'] as String,
          inviteCode: circleRow['invite_code'] as String,
          memberIds: [for (final member in members) member.profile.id],
          createdAt: DateTime.parse(circleRow['created_at'] as String).toLocal(),
        ),
        members: members,
      );
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  static String _displayName(Object? value) {
    final name = value is String ? value.trim() : '';
    return name.isEmpty ? 'Pathfinder' : name;
  }

  static CircleFailure _mapFailure(sb.PostgrestException error) {
    final message = switch (error.code) {
      '23505' => 'You are already in a circle.',
      '23514' => 'This circle is full.',
      'P0002' => 'No circle matches that invite code.',
      '42501' => 'Sign in again to continue.',
      '22023' || 'P0001' => error.message,
      _ => null,
    };
    return CircleFailure(
      message ??
          'Could not reach your circle. Check your connection and try again.',
      code: error.code,
    );
  }
}
