import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/location/domain/telemetry_cadence.dart';

void main() {
  test('charging wins over the battery level', () {
    final cadence = TelemetryCadence.forBattery(percent: 4, isCharging: true);
    expect(cadence, TelemetryCadence.charging);
  });

  test('a healthy battery keeps a steady cadence', () {
    expect(
      TelemetryCadence.forBattery(percent: 80, isCharging: false),
      TelemetryCadence.healthy,
    );
    expect(
      TelemetryCadence.forBattery(percent: 41, isCharging: false),
      TelemetryCadence.healthy,
    );
  });

  test('unknown battery falls back to the healthy cadence', () {
    expect(
      TelemetryCadence.forBattery(percent: null, isCharging: false),
      TelemetryCadence.healthy,
    );
  });

  test('mid battery starts conserving', () {
    expect(
      TelemetryCadence.forBattery(percent: 40, isCharging: false),
      TelemetryCadence.conserving,
    );
    expect(
      TelemetryCadence.forBattery(percent: 16, isCharging: false),
      TelemetryCadence.conserving,
    );
  });

  test('a low battery stretches to two-minute fixes', () {
    expect(
      TelemetryCadence.forBattery(percent: 15, isCharging: false),
      TelemetryCadence.low,
    );
    expect(
      TelemetryCadence.forBattery(percent: 0, isCharging: false),
      TelemetryCadence.low,
    );
  });

  test('every keepalive stays inside the online window', () {
    const onlineWindow = Duration(minutes: 3);
    for (final cadence in [
      TelemetryCadence.charging,
      TelemetryCadence.healthy,
      TelemetryCadence.conserving,
      TelemetryCadence.low,
      TelemetryCadence.batteryOnly,
    ]) {
      expect(cadence.keepAlive, lessThan(onlineWindow));
    }
  });

  test('a keepalive never fires faster than its own interval', () {
    for (final cadence in [
      TelemetryCadence.charging,
      TelemetryCadence.healthy,
      TelemetryCadence.conserving,
      TelemetryCadence.low,
    ]) {
      expect(cadence.keepAlive, greaterThanOrEqualTo(cadence.interval));
    }
  });
}
