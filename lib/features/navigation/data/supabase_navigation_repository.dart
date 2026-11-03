import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/navigation_destination.dart';
import '../domain/navigation_failure.dart';
import '../domain/navigation_repository.dart';

/// Reads and writes the circle's shared destination.
class SupabaseNavigationRepository implements NavigationRepository {
  SupabaseNavigationRepository(this._client, {required this.circleId});

  final sb.SupabaseClient _client;
  final String circleId;

  static const _columns = 'latitude, longitude, label, set_by, updated_at';

  @override
  Stream<NavigationDestination?> watchDestination() async* {
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
            .channel('destination-changes-$circleId')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'circle_destinations',
              callback: (_) => scheduleRefresh(),
            )
          ..subscribe();

    try {
      yield await _fetch();
      await for (final _ in changes.stream) {
        try {
          yield await _fetch();
        } catch (error) {
          developer.log(
            'Could not refresh the shared destination',
            name: 'pathfinders.navigation',
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
  Future<void> setDestination({
    required String label,
    required double latitude,
    required double longitude,
    required String setBy,
  }) async {
    try {
      await _client.from('circle_destinations').upsert({
        'circle_id': circleId,
        'label': label.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'set_by': setBy,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'circle_id');
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not share that destination. Check your connection '
            'and try again.',
      );
    } on Exception {
      throw const NavigationFailure(
        'Could not share that destination. Check your connection and try '
        'again.',
      );
    }
  }

  @override
  Future<void> clearDestination() async {
    try {
      await _client
          .from('circle_destinations')
          .delete()
          .eq('circle_id', circleId);
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not end navigation. Check your connection and try '
            'again.',
      );
    } on Exception {
      throw const NavigationFailure(
        'Could not end navigation. Check your connection and try again.',
      );
    }
  }

  Future<NavigationDestination?> _fetch() async {
    try {
      final row = await _client
          .from('circle_destinations')
          .select(_columns)
          .eq('circle_id', circleId)
          .maybeSingle();
      if (row == null) return null;

      return NavigationDestination(
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        label: row['label'] as String,
        setBy: row['set_by'] as String,
        updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
      );
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(
        error,
        fallback:
            'Could not read the shared destination. Check your '
            'connection and try again.',
      );
    }
  }

  static NavigationFailure _mapFailure(
    sb.PostgrestException error, {
    required String fallback,
  }) {
    final message = switch (error.code) {
      '23514' || '22001' => 'That destination name is a little too long.',
      '42501' || 'PGRST301' => 'Sign in again to share a destination.',
      _ => null,
    };
    return NavigationFailure(message ?? fallback, code: error.code);
  }
}
