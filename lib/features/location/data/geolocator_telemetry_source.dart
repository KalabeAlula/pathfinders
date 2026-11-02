import 'dart:async';
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../domain/device_telemetry.dart';
import '../domain/geo_point.dart';
import '../domain/speed_filter.dart';

class GeolocatorTelemetrySource implements DeviceTelemetrySource {
  GeolocatorTelemetrySource([Battery? battery])
    : _battery = battery ?? Battery();

  static const Duration _fixTimeout = Duration(seconds: 20);

  final Battery _battery;
  final StationarySpeedFilter _speedFilter = StationarySpeedFilter();

  @override
  Future<TelemetryPermission> checkPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return TelemetryPermission.servicesDisabled;
      }
      return _map(await Geolocator.checkPermission());
    } on MissingPluginException {
      return TelemetryPermission.unsupported;
    } on UnsupportedError {
      return TelemetryPermission.unsupported;
    }
  }

  @override
  Future<TelemetryPermission> requestPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return TelemetryPermission.servicesDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return _map(permission);
    } on MissingPluginException {
      return TelemetryPermission.unsupported;
    } on UnsupportedError {
      return TelemetryPermission.unsupported;
    }
  }

  @override
  Future<bool> hasBackgroundAccess() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.checkPermission() == LocationPermission.always;
    } on MissingPluginException {
      return false;
    } on UnsupportedError {
      return false;
    }
  }

  @override
  Future<bool> requestBackgroundAccess() async {
    if (kIsWeb) return false;
    try {
      if (await hasBackgroundAccess()) return true;

      final status = await permissions.Permission.locationAlways.request();
      if (status.isGranted) return true;

      // Android 11+ refuses to show the background prompt inline and iOS stops
      // prompting once the member has answered, so Settings is the only route.
      await openAppSettings();
      return await hasBackgroundAccess();
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final current = await permissions.Permission.notification.status;
      if (current.isGranted) return true;
      final result = await permissions.Permission.notification.request();
      return result.isGranted;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<DeviceReading> positionUpdates({
    required Duration interval,
    required double distanceFilter,
  }) {
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            intervalDuration: interval,
            distanceFilter: distanceFilter.round(),
            // This is what keeps fixes coming once the app leaves the screen:
            // the foreground service holds the process up and the persistent
            // notification is the member's reminder that sharing is live.
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Pathfinders is sharing your location',
              notificationText:
                  'Your circle can see where you are until you pause sharing.',
              notificationChannelName: 'Location sharing',
              notificationIcon: AndroidResource(
                name: 'ic_stat_pathfinders',
                defType: 'drawable',
              ),
              setOngoing: true,
            ),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: distanceFilter.round(),
            allowBackgroundLocationUpdates: true,
            showBackgroundLocationIndicator: true,
            pauseLocationUpdatesAutomatically: false,
            activityType: ActivityType.other,
          );

    return Geolocator.getPositionStream(locationSettings: settings)
        .map(_toReading);
  }

  @override
  Future<DeviceReading?> currentReading() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _fixTimeout,
        ),
      );
      return _toReading(position);
    } on TimeoutException {
      return null;
    } on LocationServiceDisabledException {
      return null;
    } on PermissionDeniedException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<BatteryReading> battery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      return BatteryReading(
        percent: level.clamp(0, 100),
        isCharging:
            state == BatteryState.charging || state == BatteryState.full,
      );
    } on MissingPluginException {
      return const BatteryReading(percent: null, isCharging: false);
    } on PlatformException {
      return const BatteryReading(percent: null, isCharging: false);
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  DeviceReading _toReading(Position position) {
    final speed = position.hasSpeed && position.speed.isFinite
        ? math.max(position.speed, 0.0)
        : 0.0;
    final speedAccuracy =
        position.hasSpeedAccuracy && position.speedAccuracy.isFinite
        ? math.max(position.speedAccuracy, 0.0)
        : 0.0;
    final accuracy = position.hasAccuracy && position.accuracy.isFinite
        ? math.max(position.accuracy, 0.0)
        : 0.0;

    return _speedFilter.apply(
      point: GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      accuracyMeters: accuracy,
      speedKph: speed * 3.6,
      speedAccuracyKph: speedAccuracy * 3.6,
    );
  }

  static TelemetryPermission _map(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => TelemetryPermission.granted,
      LocationPermission.deniedForever => TelemetryPermission.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => TelemetryPermission.denied,
    };
  }
}
