import 'geo_point.dart';

/// One position fix from the device.
class DeviceReading {
  const DeviceReading({
    required this.point,
    required this.accuracyMeters,
    required this.speedKph,
    this.speedAccuracyKph = 0,
    this.headingDegrees,
  });

  final GeoPoint point;
  final double accuracyMeters;

  /// Already filtered for stationary drift; exactly 0 means the device is
  /// still. Raw GPS speed must never reach this field unfiltered.
  final double speedKph;

  /// How wrong the platform thinks [speedKph] is; 0 when it did not say.
  final double speedAccuracyKph;

  /// Direction of travel in degrees clockwise from north, or null when the
  /// platform could not compute one (which is common while standing still).
  final double? headingDegrees;
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

  /// Whether the OS will hand over fixes while the app is off-screen.
  Future<bool> hasBackgroundAccess();

  /// Raises sharing to "always" and reports the result. On Android 11+ this
  /// detours through system settings, because the OS stopped showing the
  /// background prompt inline.
  Future<bool> requestBackgroundAccess();

  /// True when the member will see the tracking notification. Android hides
  /// it without permission, which is the only sign that sharing still runs.
  Future<bool> requestNotificationPermission();

  /// A single fix, or null when the device cannot produce one right now.
  Future<DeviceReading?> currentReading();

  /// Fixes as the OS delivers them, including while the app is off-screen.
  /// [interval] and [distanceFilter] are hints the platform may round.
  Stream<DeviceReading> positionUpdates({
    required Duration interval,
    required double distanceFilter,
  });

  Future<BatteryReading> battery();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}
