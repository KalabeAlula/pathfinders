import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../location/data/member_status_mapper.dart';
import '../domain/circle.dart';
import '../domain/circle_failure.dart';
import '../domain/circle_member.dart';
import '../domain/circle_repository.dart';
import '../domain/circle_snapshot.dart';
import '../domain/circle_summary.dart';
import '../domain/group_type.dart';
import '../domain/user_profile.dart';

/// Reads the signed-in user's groups and refreshes them on realtime changes.
///
/// Every membership is watched through its own channel so switching groups
/// disposes exactly the old stream; there is no shared channel that could leak
/// a listener from the group the member just left.
class SupabaseCircleRepository implements CircleRepository {
  SupabaseCircleRepository(this._client, {required this.userId});

  final sb.SupabaseClient _client;
  final String userId;
  int _channelSequence = 0;

  @override
  Stream<List<CircleSummary>> watchCircles() {
    return _liveStream(
      channelName: 'circle-list-$userId-${_channelSequence++}',
      tables: const ['circle_members', 'circles'],
      fetch: _fetchSummaries,
    );
  }

  @override
  Stream<CircleSnapshot?> watchCircle(String circleId) {
    return _liveStream(
      channelName: 'circle-$circleId-$userId-${_channelSequence++}',
      tables: const ['circle_members', 'circles', 'member_status'],
      fetch: () => _fetch(circleId),
    );
  }

  Stream<T> _liveStream<T>({
    required String channelName,
    required List<String> tables,
    required Future<T> Function() fetch,
  }) async* {
    final changes = StreamController<void>.broadcast();
    Timer? debounce;

    void scheduleRefresh() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 250), () {
        if (!changes.isClosed) changes.add(null);
      });
    }

    var channel = _client.channel(channelName);
    for (final table in tables) {
      channel = channel.onPostgresChanges(
        event: sb.PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => scheduleRefresh(),
      );
    }
    channel.subscribe();

    try {
      yield await fetch();
      await for (final _ in changes.stream) {
        try {
          yield await fetch();
        } catch (error) {
          // Keep showing the last good state; the next event retries.
          developer.log(
            'Could not refresh circle data',
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
  Future<Circle> createCircle({
    required String name,
    required GroupType type,
    required String petId,
    required String petName,
  }) async {
    final row = await _runRpc(
      () => _client.rpc(
        'create_circle',
        params: {
          'p_name': name.trim(),
          'p_group_type': type.dbValue,
          'p_pet_id': petId.trim(),
          'p_pet_name': petName.trim(),
        },
      ),
    );
    return Circle.fromRow(row, memberIds: [userId]);
  }

  @override
  Future<Circle> joinCircle({required String code}) async {
    final row = await _runRpc(
      () => _client.rpc(
        'join_circle',
        params: {'p_code': code.trim().toUpperCase()},
      ),
    );
    return Circle.fromRow(row, memberIds: [userId]);
  }

  @override
  Future<void> leaveCircle({required String circleId}) {
    return _runVoidRpc(
      () => _client.rpc('leave_circle', params: {'p_circle_id': circleId}),
    );
  }

  @override
  Future<void> deleteCircle({required String circleId}) {
    return _runVoidRpc(
      () => _client.rpc('delete_circle', params: {'p_circle_id': circleId}),
    );
  }

  @override
  Future<void> renameCircle({required String circleId, required String name}) {
    return _runVoidRpc(
      () => _client.rpc(
        'rename_circle',
        params: {'p_circle_id': circleId, 'p_name': name.trim()},
      ),
    );
  }

  @override
  Future<String> rotateInviteCode({required String circleId}) async {
    try {
      final data = await _client.rpc(
        'rotate_invite_code',
        params: {'p_circle_id': circleId},
      );
      if (data is String && data.isNotEmpty) return data;
      throw const CircleFailure('Could not issue a new invite code.');
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> removeMember({
    required String circleId,
    required String memberId,
  }) {
    return _runVoidRpc(
      () => _client.rpc(
        'remove_circle_member',
        params: {'p_circle_id': circleId, 'p_user_id': memberId},
      ),
    );
  }

  @override
  Future<void> transferOwnership({
    required String circleId,
    required String newOwnerId,
  }) {
    return _runVoidRpc(
      () => _client.rpc(
        'transfer_circle_ownership',
        params: {'p_circle_id': circleId, 'p_new_owner': newOwnerId},
      ),
    );
  }

  Future<void> _runVoidRpc(Future<Object?> Function() call) async {
    try {
      await call();
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  Future<Map<String, dynamic>> _runRpc(Future<Object?> Function() call) async {
    try {
      final data = await call();
      if (data is Map<String, dynamic>) return data;
      return Map<String, dynamic>.from(data as Map);
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  Future<List<CircleSummary>> _fetchSummaries() async {
    try {
      final membershipRows = await _client
          .from('circle_members')
          .select('circle_id')
          .eq('user_id', userId)
          .order('joined_at', ascending: true);

      final orderedIds = [
        for (final row in membershipRows) row['circle_id'] as String,
      ];
      if (orderedIds.isEmpty) return const [];

      final circleRows = await _client
          .from('circles')
          .select(
            'id, name, group_type, pet_id, pet_species, pet_name, pet_level, '
            'created_at',
          )
          .inFilter('id', orderedIds);

      final memberRows = await _client
          .from('circle_members')
          .select('circle_id')
          .inFilter('circle_id', orderedIds);

      final counts = <String, int>{};
      for (final row in memberRows) {
        final id = row['circle_id'] as String;
        counts[id] = (counts[id] ?? 0) + 1;
      }

      final rowsById = {for (final row in circleRows) row['id'] as String: row};

      return [
        for (final id in orderedIds)
          if (rowsById[id] case final row?)
            CircleSummary.fromRow(row, memberCount: counts[id] ?? 1),
      ];
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  Future<CircleSnapshot?> _fetch(String circleId) async {
    try {
      final circleRow = await _client
          .from('circles')
          .select(
            'id, name, invite_code, group_type, created_by, pet_id, '
            'pet_species, pet_name, '
            'pet_level, pet_mood, pet_experience, pet_hunger, pet_energy, '
            'pet_hygiene, pet_happiness, pet_last_action, pet_last_action_at, '
            'pet_updated_at, created_at',
          )
          .eq('id', circleId)
          .maybeSingle();
      if (circleRow == null) return null;

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
        circle: Circle.fromRow(
          circleRow,
          memberIds: [for (final member in members) member.profile.id],
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
      '23505' => 'You are already in this circle.',
      '23514' => 'This circle is full.',
      'P0002' =>
        error.message.trim().isEmpty
            ? 'No circle matches that invite code.'
            : error.message,
      // RPCs raise 42501 with their own copy; keep it when present.
      '42501' =>
        error.message.trim().isEmpty
            ? 'Sign in again to continue.'
            : error.message,
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
