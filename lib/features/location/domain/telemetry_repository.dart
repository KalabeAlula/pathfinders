import 'geo_point.dart';
import 'privacy_mode.dart';

/// Writes this member's telemetry to the circle.
///
/// Masking happens on the server: a paused member's coordinates are never
/// stored, and an approximate member's are snapped before they are persisted.
abstract interface class TelemetryRepository {
  Future<PrivacyMode> loadPrivacyMode();

  Future<void> setPrivacyMode(PrivacyMode mode);

  Future<void> report({
    GeoPoint? point,
    double accuracyMeters = 0,
    double speedKph = 0,
    int? batteryPercent,
    bool isCharging = false,
  });
}
