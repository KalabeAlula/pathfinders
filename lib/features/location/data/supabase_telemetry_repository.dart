import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/geo_point.dart';
import '../domain/privacy_mode.dart';
import '../domain/telemetry_failure.dart';
import '../domain/telemetry_repository.dart';

class SupabaseTelemetryRepository implements TelemetryRepository {
  SupabaseTelemetryRepository(this._client, {required this.userId});

  final sb.SupabaseClient _client;
  final String userId;

  @override
  Future<PrivacyMode> loadPrivacyMode() async {
    try {
      final row = await _client
          .from('member_status')
          .select('privacy_mode')
          .eq('user_id', userId)
          .maybeSingle();
      return _modeFromName(row?['privacy_mode'] as String?);
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> setPrivacyMode(PrivacyMode mode) => _run(
        () => _client.rpc(
          'set_privacy_mode',
          params: {'p_mode': mode.name},
        ),
      );

  @override
  Future<void> report({
    GeoPoint? point,
    double accuracyMeters = 0,
    double speedKph = 0,
    int? batteryPercent,
    bool isCharging = false,
  }) =>
      _run(
        () => _client.rpc(
          'report_status',
          params: {
            'p_latitude': point?.latitude,
            'p_longitude': point?.longitude,
            'p_accuracy_meters': accuracyMeters,
            'p_battery_percent': batteryPercent,
            'p_is_charging': isCharging,
            'p_speed_kph': speedKph,
          },
        ),
      );

  Future<void> _run(Future<Object?> Function() call) async {
    try {
      await call();
    } on sb.PostgrestException catch (error) {
      throw _mapFailure(error);
    }
  }

  static PrivacyMode _modeFromName(String? name) => switch (name) {
        'approximate' => PrivacyMode.approximate,
        'paused' => PrivacyMode.paused,
        _ => PrivacyMode.exact,
      };

  static TelemetryFailure _mapFailure(sb.PostgrestException error) {
    final message = switch (error.code) {
      '42501' => 'Sign in again to keep sharing.',
      '22023' || 'P0001' => error.message,
      _ => null,
    };
    return TelemetryFailure(
      message ?? 'Could not reach your circle. Check your connection.',
      code: error.code,
    );
  }
}
