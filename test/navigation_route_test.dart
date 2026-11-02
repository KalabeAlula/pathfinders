import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/utils/time_format.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/navigation/data/polyline_decoder.dart';
import 'package:pathfinders/features/navigation/domain/route_geometry.dart';
import 'package:pathfinders/features/navigation/domain/route_plan.dart';
import 'package:pathfinders/features/navigation/domain/route_progress.dart';

void main() {
  group('decodePolyline', () {
    test('matches the reference precision-5 example', () {
      final points = decodePolyline(r'_p~iF~ps|U_ulLnnqC_mqNvxq`@');

      expect(points, hasLength(3));
      expect(points[0].latitude, closeTo(38.5, 1e-5));
      expect(points[0].longitude, closeTo(-120.2, 1e-5));
      expect(points[1].latitude, closeTo(40.7, 1e-5));
      expect(points[1].longitude, closeTo(-120.95, 1e-5));
      expect(points[2].latitude, closeTo(43.252, 1e-5));
      expect(points[2].longitude, closeTo(-126.453, 1e-5));
    });

    test('returns nothing for an empty geometry', () {
      expect(decodePolyline(''), isEmpty);
    });
  });

  group('route geometry', () {
    test('measures a degree of longitude at the equator', () {
      final distance = distanceMeters(
        const GeoPoint(latitude: 0, longitude: 0),
        const GeoPoint(latitude: 0, longitude: 1),
      );
      expect(distance, closeTo(111195, 300));
    });

    test('finds the closest point on a route line', () {
      final line = [
        const GeoPoint(latitude: 0, longitude: 0),
        const GeoPoint(latitude: 0, longitude: 0.001),
      ];

      expect(
        distanceToLineMeters(
          const GeoPoint(latitude: 0.0005, longitude: 0.0005),
          line,
        ),
        closeTo(55.6, 2),
      );
      expect(
        distanceToLineMeters(
          const GeoPoint(latitude: 0.01, longitude: 0.0005),
          line,
        ),
        closeTo(1112, 30),
      );
    });

    test('handles a single-point or empty line', () {
      const point = GeoPoint(latitude: 9, longitude: 38.7);
      expect(distanceToLineMeters(point, const []), double.infinity);
      expect(
        distanceToLineMeters(
          const GeoPoint(latitude: 9, longitude: 38.8),
          const [point],
        ),
        greaterThan(0),
      );
    });
  });

  group('route plan', () {
    test('derives the ETA and arrival threshold', () {
      final plan = RoutePlan(
        geometry: const [],
        distanceMeters: 20,
        duration: const Duration(minutes: 12),
        fetchedAt: DateTime(2026, 11, 1, 18),
      );

      expect(plan.eta, DateTime(2026, 11, 1, 18, 12));
      expect(plan.hasArrived, isTrue);
    });
  });

  group('route progress', () {
    const start = GeoPoint(latitude: 0, longitude: 0);
    const middle = GeoPoint(latitude: 0, longitude: 0.005);
    const finish = GeoPoint(latitude: 0, longitude: 0.01);
    const geometry = [start, finish];
    final plan = RoutePlan(
      geometry: geometry,
      distanceMeters: 1112,
      duration: const Duration(minutes: 10),
      fetchedAt: DateTime(2026, 11, 2, 9),
    );

    test('measures how far along the polyline a fix sits', () {
      final location = progressAlongLine(middle, geometry);
      expect(location.total, closeTo(1112, 3));
      expect(location.travelled, closeTo(556, 3));
      expect(progressAlongLine(middle, const []), (travelled: 0.0, total: 0.0));
    });

    test('shrinks remaining distance and time as the member advances', () {
      final progress = RouteProgress.from(
        plan,
        middle,
        now: DateTime(2026, 11, 2, 9, 5),
      );

      expect(progress.remainingMeters, closeTo(556, 3));
      expect(progress.remaining, const Duration(minutes: 5));
      expect(progress.arrival, DateTime(2026, 11, 2, 9, 10));
      expect(progress.arrived, isFalse);
    });

    test('clamps fixes behind the start or past the end', () {
      final behind = RouteProgress.from(
        plan,
        const GeoPoint(latitude: 0, longitude: -0.005),
        now: DateTime(2026, 11, 2, 9),
      );
      expect(behind.remainingMeters, closeTo(plan.distanceMeters, 1));

      final past = RouteProgress.from(
        plan,
        const GeoPoint(latitude: 0, longitude: 0.02),
        now: DateTime(2026, 11, 2, 9),
      );
      expect(past.remainingMeters, 0);
      expect(past.arrived, isTrue);
    });
  });

  group('route formatting', () {
    test('keeps metric distances readable', () {
      expect(formatRouteDistance(850), '850 m');
      expect(formatRouteDistance(4250), '4.3 km');
      expect(formatRouteDistance(25000), '25 km');
      expect(formatRouteDistance(double.nan), '—');
    });

    test('compresses travel time for map chips', () {
      expect(formatRouteEta(const Duration(seconds: 40)), 'now');
      expect(formatRouteEta(const Duration(minutes: 18)), '18m');
      expect(formatRouteEta(const Duration(minutes: 80)), '1h 20m');
      expect(formatRouteEta(const Duration(hours: 2)), '2h');
    });
  });
}
