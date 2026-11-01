import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/device_telemetry.dart';
import '../domain/geo_point.dart';

class GeolocatorTelemetrySource implements DeviceTelemetrySource {
  GeolocatorTelemetrySource([Battery? battery]) : _battery = battery ?? Battery();

  static const Duration _fixTimeout = Duration(seconds: 20);

  final Battery _battery;

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

  static TelemetryPermission _map(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        TelemetryPermission.granted,
      LocationPermission.deniedForever => TelemetryPermission.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine =>
        TelemetryPermission.denied,
    };
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
      final speed = position.speed;
      return DeviceReading(
        point: GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        accuracyMeters:
            position.accuracy.isFinite ? position.accuracy : 0,
        speedKph: speed.isFinite && speed > 0 ? speed * 3.6 : 0,
      );
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
}
