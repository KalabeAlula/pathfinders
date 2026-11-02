import 'dart:math' as math;

import '../../../core/utils/geo_math.dart';
import 'device_telemetry.dart';
import 'geo_point.dart';

/// Turns raw GPS speed into something a person sitting still would recognise.
///
/// A phone indoors reports a couple of km/h from multipath and drifting
/// satellite geometry. A reading is only believed when it clears a deadband,
/// the platform trusts its own speed estimate, and the point actually moved
/// further than the fix's error radius.
class StationarySpeedFilter {
  StationarySpeedFilter({
    this.deadbandKph = 3.6,
    this.maxSpeedAccuracyKph = 5.4,
  });

  /// Anything slower than a brisk walk is treated as noise.
  final double deadbandKph;

  /// Speed estimates this poor, and worse than the speed they describe, are
  /// treated as noise rather than as movement.
  final double maxSpeedAccuracyKph;

  GeoPoint? _previousPoint;
  double _previousAccuracy = 0;

  DeviceReading apply({
    required GeoPoint point,
    required double accuracyMeters,
    required double speedKph,
    double speedAccuracyKph = 0,
  }) {
    final previous = _previousPoint;
    final driftMeters = math.max(accuracyMeters, _previousAccuracy);
    final movedMeters = previous == null
        ? double.infinity
        : distanceMeters(
            latA: previous.latitude,
            lonA: previous.longitude,
            latB: point.latitude,
            lonB: point.longitude,
          );

    final trusted =
        speedAccuracyKph <= 0 ||
        speedAccuracyKph <= math.max(maxSpeedAccuracyKph, speedKph);
    final moving =
        speedKph >= deadbandKph && trusted && movedMeters >= driftMeters;

    _previousPoint = point;
    _previousAccuracy = accuracyMeters;

    return DeviceReading(
      point: point,
      accuracyMeters: accuracyMeters,
      speedKph: moving ? speedKph : 0,
      speedAccuracyKph: speedAccuracyKph,
    );
  }
}
