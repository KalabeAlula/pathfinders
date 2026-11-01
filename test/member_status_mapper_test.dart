import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/location/data/member_status_mapper.dart';
import 'package:pathfinders/features/location/domain/privacy_mode.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 18, 0);

  Map<String, dynamic> row({
    String mode = 'exact',
    double? latitude = 9.0138,
    double? longitude = 38.7665,
    int? battery = 68,
    String updatedAt = '2026-11-01T17:59:30.000Z',
    String? arrivedAt = '2026-11-01T15:45:00.000Z',
    double speedKph = 0,
  }) {
    return {
      'user_id': 'kaleab',
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': 12.0,
      'battery_percent': battery,
      'is_charging': true,
      'speed_kph': speedKph,
      'privacy_mode': mode,
      'arrived_at': arrivedAt,
      'updated_at': updatedAt,
    };
  }

  test('exact rows keep their point and dwell', () {
    final status = MemberStatusMapper.fromRow(row(), now: now);

    expect(status.location?.latitude, 9.0138);
    expect(status.location?.longitude, 38.7665);
    expect(status.privacyMode, PrivacyMode.exact);
    expect(status.isOnline, isTrue);
    expect(status.isCharging, isTrue);
    expect(status.isLowBattery, isFalse);
    expect(status.dwellTime(now)?.inHours, 2);
  });

  test('paused rows carry no coordinates', () {
    final status = MemberStatusMapper.fromRow(
      row(
        mode: 'paused',
        latitude: null,
        longitude: null,
        arrivedAt: null,
        speedKph: 22,
      ),
      now: now,
    );

    expect(status.isPaused, isTrue);
    expect(status.location, isNull);
    expect(status.hasLocation, isFalse);
    expect(status.dwellTime(now), isNull);
  });

  test('approximate rows stay flagged even though the server snapped them', () {
    final status = MemberStatusMapper.fromRow(
      row(mode: 'approximate', latitude: 9.012, longitude: 38.766),
      now: now,
    );

    expect(status.isApproximate, isTrue);
    expect(status.isPaused, isFalse);
    expect(status.location, isNotNull);
  });

  test('online is derived from how fresh the row is', () {
    final stale = MemberStatusMapper.fromRow(
      row(updatedAt: '2026-11-01T17:50:00.000Z'),
      now: now,
    );

    expect(stale.isOnline, isFalse);
  });

  test('a missing battery reading is not treated as low battery', () {
    final status = MemberStatusMapper.fromRow(
      row(battery: null),
      now: now,
    );

    expect(status.batteryPercent, isNull);
    expect(status.isLowBattery, isFalse);
  });

  test('unknown modes fall back to exact', () {
    final status = MemberStatusMapper.fromRow(row(mode: 'nonsense'), now: now);

    expect(status.privacyMode, PrivacyMode.exact);
  });
}
