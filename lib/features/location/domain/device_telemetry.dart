import 'geo_point.dart';

/// One position fix from the device.
class DeviceReading {
  const DeviceReading({
    required this.point,
    required this.accuracyMeters,
    required this.speedKph,
  });

  final GeoPoint point;
  final double accuracyMeters;
  final double speedKph;
}

/// What the device can tell us about its battery right now.
///
/// [percent] is null when the platform will not report a level, which is
/// different from a flat battery.
class BatteryReading {
  const BatteryReading({required this.percent, required this.isCharging});

  final int? percent;
  final bool isCharging;
}

enum TelemetryPermission {
  /// Location can be read now.
  granted,

  /// The platform will still show a prompt next time we ask.
  denied,

  /// The user blocked location; only system settings can undo it.
  deniedForever,

  /// System location is switched off for the whole device.
  servicesDisabled,

  /// This platform has no location plugin (desktop without a provider).
  unsupported,
}

abstract interface class DeviceTelemetrySource {
  /// Current access, without showing a system prompt.
  Future<TelemetryPermission> checkPermission();

  /// May show the system prompt. Only called after the member opts in.
  Future<TelemetryPermission> requestPermission();

  /// A single fix, or null when the device cannot produce one right now.
  Future<DeviceReading?> currentReading();

  Future<BatteryReading> battery();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}
