import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/milestones_failure.dart';
import '../domain/milestones_repository.dart';
import '../domain/shared_milestone.dart';
import 'milestones_cache.dart';

/// Reads and writes the shared countdown for one circle.
class SupabaseMilestonesRepository implements MilestonesRepository {
  SupabaseMilestonesRepository(
    this._client, {
    required this.circleId,
    this.cache,
  });

  final sb.SupabaseClient _client;
  final MilestonesCache? cache;
  final String circleId;

  static const _columns =
      'id, title, subtitle, due_on, starts_at, place, kind, created_at';

  @override
  Stream<List<SharedMilestone>> watchMilestones() async* {
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
            .channel('milestones-changes-$circleId')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'milestones',
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
        // The cached list is still worth showing; realtime may recover.
        developer.log(
          'Could not refresh milestones',
          name: 'pathfinders.milestones',
          error: error,
        );
      }

      await for (final _ in changes.stream) {
        try {
          yield await _fetchAndCache();
        } catch (error) {
          // Keep showing the last good list; the next event retries.
          developer.log(
            'Could not refresh milestones',
            name: 'pathfinders.milestones',
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
  Future<void> addMilestone({
    required String createdBy,
    required String title,
    required DateTime date,
    required MilestoneKind kind,
    String? subtitle,
    DateTime? startsAt,
    String? place,
  }) async {
    final note = subtitle?.trim();
    final spot = place?.trim();
    final start = startsAt;
    try {
      await _client.from('milestones').insert({
        'circle_id': circleId,
        'created_by': createdBy,
        'title': title.trim(),
        'due_on': _dateOnly(date),
        'kind': kind.name,
        if (start != null) 'starts_at': _timeOnly(start),
        if (note != null && note.isNotEmpty) 'subtitle': note,
        if (spot != null && spot.isNotEmpty) 'place': spot,
      });
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not save that countdown. Check your connection and '
            'try again.',
      );
    } on Exception {
      throw const MilestonesFailure(
        'Could not save that countdown. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> setPlace({
    required String milestoneId,
    required String? place,
  }) async {
    final spot = place?.trim();
    final List<Map<String, dynamic>> updated;
    try {
      updated = await _client
          .from('milestones')
          .update({'place': spot == null || spot.isEmpty ? null : spot})
          .eq('id', milestoneId)
          .select('id');
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not save the place. Check your connection and try again.',
        tooLong: 'That place is a little too long.',
      );
    } on Exception {
      throw const MilestonesFailure(
        'Could not save the place. Check your connection and try again.',
      );
    }

    // RLS filters rows instead of failing, so an unclaimed update means the
    // member is no longer allowed to plan for this circle.
    if (updated.isEmpty) {
      throw const MilestonesFailure(
        'Could not update that countdown. Pull to refresh and try again.',
      );
    }
  }

  Future<List<SharedMilestone>> _fetchAndCache() async {
    final milestones = await _fetch();
    try {
      await cache?.write(milestones);
    } on Exception {
      // A failed cache write must not hide a fresh list.
    }
    return milestones;
  }

  Future<List<SharedMilestone>> _fetch() async {
    try {
      final rows = await _client
          .from('milestones')
          .select(_columns)
          .eq('circle_id', circleId)
          .order('due_on', ascending: true);

      return [
        for (final row in rows)
          SharedMilestone(
            id: row['id'] as String,
            title: row['title'] as String,
            date: DateTime.parse(row['due_on'] as String),
            kind: _kind(row['kind']),
            subtitle: _optionalLabel(row['subtitle']),
            startsAt: _startsAt(
              row['due_on'] as String,
              row['starts_at'],
            ),
            place: _optionalLabel(row['place']),
          ),
      ];
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not reach your milestones. Check your connection and '
            'try again.',
      );
    }
  }

  static MilestoneKind _kind(Object? value) => MilestoneKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => MilestoneKind.goal,
  );

  static String? _optionalLabel(Object? value) {
    if (value is! String) return null;
    final label = value.trim();
    return label.isEmpty ? null : label;
  }

  static String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Combines the stored `time` column with the milestone's day.
  static DateTime? _startsAt(String dueOn, Object? value) {
    if (value is! String) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final day = DateTime.tryParse(dueOn);
    if (hour == null || minute == null || day == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  static String _timeOnly(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  static MilestonesFailure _mapFailure(
    sb.PostgrestException error, {
    required String fallback,
    String tooLong = 'That title or note is a little too long.',
  }) {
    final message = switch (error.code) {
      '23514' || '22001' => tooLong,
      '42501' || 'PGRST301' => 'Sign in again to save this countdown.',
      _ => null,
    };
    return MilestonesFailure(message ?? fallback, code: error.code);
  }
}
