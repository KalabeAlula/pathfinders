import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/location/domain/speed_filter.dart';

void main() {
  const origin = GeoPoint(latitude: 9, longitude: 38.75);

  // Roughly 111 m per 0.001 degree of latitude.
  const drifted = GeoPoint(latitude: 9.00005, longitude: 38.75);
  const walked = GeoPoint(latitude: 9.0003, longitude: 38.75);

  test('sub-walk speed is clamped to zero', () {
    final reading = StationarySpeedFilter().apply(
      point: origin,
      accuracyMeters: 5,
      speedKph: 2.9,
    );

    expect(reading.speedKph, 0);
  });

  test('a brisk walk clears the deadband', () {
    final reading = StationarySpeedFilter().apply(
      point: origin,
      accuracyMeters: 5,
      speedKph: 5.2,
    );

    expect(reading.speedKph, 5.2);
  });

  test('movement inside the accuracy radius is drift, not travel', () {
    final filter = StationarySpeedFilter();
    filter.apply(point: origin, accuracyMeters: 15, speedKph: 0);

    final second = filter.apply(
      point: drifted,
      accuracyMeters: 15,
      speedKph: 6,
    );

    expect(second.speedKph, 0);
  });

  test('real travel beyond the accuracy radius keeps its speed', () {
    final filter = StationarySpeedFilter();
    filter.apply(point: origin, accuracyMeters: 8, speedKph: 0);

    final second = filter.apply(point: walked, accuracyMeters: 8, speedKph: 8);

    expect(second.speedKph, 8);
  });

  test('an untrustworthy speed estimate is treated as still', () {
    final reading = StationarySpeedFilter().apply(
      point: origin,
      accuracyMeters: 4,
      speedKph: 6,
      speedAccuracyKph: 15,
    );

    expect(reading.speedKph, 0);
  });

  test('a stationary reading still carries its point and accuracy', () {
    final reading = StationarySpeedFilter().apply(
      point: origin,
      accuracyMeters: 12,
      speedKph: 0.8,
    );

    expect(reading.point.latitude, 9);
    expect(reading.accuracyMeters, 12);
    expect(reading.speedKph, 0);
  });
}
