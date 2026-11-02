import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/location/application/telemetry_providers.dart';
import 'package:pathfinders/features/location/domain/device_telemetry.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/location/domain/member_status.dart';
import 'package:pathfinders/features/location/domain/privacy_mode.dart';
import 'package:pathfinders/features/location/domain/telemetry_cadence.dart';
import 'package:pathfinders/features/location/domain/telemetry_repository.dart';

class _RecordingRepository implements TelemetryRepository {
  int reports = 0;
  GeoPoint? lastPoint;

  @override
  Future<PrivacyMode> loadPrivacyMode() async => PrivacyMode.exact;

  @override
  Future<void> setPrivacyMode(PrivacyMode mode) async {}

  @override
  Future<void> report({
    GeoPoint? point,
    double accuracyMeters = 0,
    double speedKph = 0,
    int? batteryPercent,
    bool isCharging = false,
  }) async {
    reports++;
    if (point != null) lastPoint = point;
  }
}

class _FakeSource implements DeviceTelemetrySource {
  final updates = StreamController<DeviceReading>.broadcast();

  @override
  Future<TelemetryPermission> checkPermission() async =>
      TelemetryPermission.granted;

  @override
  Future<TelemetryPermission> requestPermission() async =>
      TelemetryPermission.granted;

  @override
  Future<bool> hasBackgroundAccess() async => true;

  @override
  Future<bool> requestBackgroundAccess() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<DeviceReading?> currentReading() async => null;

  @override
  Stream<DeviceReading> positionUpdates({
    required Duration interval,
    required double distanceFilter,
  }) => updates.stream;

  @override
  Future<BatteryReading> battery() async =>
      const BatteryReading(percent: 80, isCharging: true);

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a stationary member keeps heartbeating the last known point', () {
    fakeAsync((async) {
      final repository = _RecordingRepository();
      final source = _FakeSource();
      final container = ProviderContainer(
        overrides: [
          telemetryRepositoryProvider('user').overrideWithValue(repository),
          deviceTelemetrySourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(source.updates.close);

      final subscription = container.listen(
        telemetryControllerProvider('user'),
        (_, _) {},
      );
      addTearDown(subscription.close);
      async.flushMicrotasks();

      // Launch sends a presence heartbeat even before a fix arrives.
      expect(repository.reports, greaterThan(0));

      source.updates.add(
        const DeviceReading(
          point: GeoPoint(latitude: 9, longitude: 38.75),
          accuracyMeters: 5,
          speedKph: 0,
        ),
      );
      async.flushMicrotasks();
      final afterFix = repository.reports;
      expect(repository.lastPoint, isNotNull);

      // No further fix ever arrives; battery is charging, so the keepalive
      // fires every 45 seconds.
      async.elapse(const Duration(seconds: 50));
      async.flushMicrotasks();
      expect(repository.reports, greaterThan(afterFix));

      async.elapse(const Duration(seconds: 50));
      async.flushMicrotasks();
      expect(repository.reports, greaterThan(afterFix + 1));
      expect(repository.lastPoint, isNotNull);
    });
  });

  test('every keepalive leaves room inside the online window', () {
    const cadences = [
      TelemetryCadence.charging,
      TelemetryCadence.healthy,
      TelemetryCadence.conserving,
      TelemetryCadence.low,
      TelemetryCadence.batteryOnly,
    ];

    for (final cadence in cadences) {
      expect(
        cadence.keepAlive * 2,
        lessThanOrEqualTo(MemberStatus.onlineWindow),
        reason: '${cadence.keepAlive} is too close to the online window',
      );
    }
  });
}
