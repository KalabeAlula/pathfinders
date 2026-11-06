import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/utils/time_format.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/navigation/domain/navigation_maneuver.dart';
import 'package:pathfinders/features/navigation/domain/route_geometry.dart';
import 'package:pathfinders/features/navigation/domain/route_plan.dart';
import 'package:pathfinders/features/navigation/domain/route_step.dart';

void main() {
  const start = GeoPoint(latitude: 0, longitude: 0);
  const middle = GeoPoint(latitude: 0, longitude: 0.005);
  const finish = GeoPoint(latitude: 0, longitude: 0.01);

  RouteStep step(
    ManeuverKind kind,
    GeoPoint at, {
    String road = '',
    int? exit,
  }) => RouteStep(
    kind: kind,
    roadName: road,
    distanceMeters: 0,
    duration: Duration.zero,
    location: at,
    exitNumber: exit,
  );

  group('NavigationManeuver', () {
    final plan = RoutePlan(
      geometry: const [start, middle, finish],
      distanceMeters: 1112,
      duration: const Duration(minutes: 10),
      steps: [
        step(ManeuverKind.depart, start, road: 'Bole Road'),
        step(ManeuverKind.turnLeft, middle, road: 'Africa Ave'),
        step(ManeuverKind.arrive, finish, road: 'Century Mall'),
      ],
      fetchedAt: DateTime(2026, 11, 6, 14),
    );

    test('picks the next turn and the maneuver after it', () {
      final maneuver = NavigationManeuver.from(
        plan,
        const GeoPoint(latitude: 0, longitude: 0.002),
      );

      expect(maneuver, isNotNull);
      expect(maneuver!.next.kind, ManeuverKind.turnLeft);
      expect(maneuver.next.roadName, 'Africa Ave');
      expect(maneuver.distanceMeters, closeTo(334, 5));
      expect(maneuver.following?.kind, ManeuverKind.arrive);
    });

    test('moves on once the turn is behind the member', () {
      final maneuver = NavigationManeuver.from(
        plan,
        const GeoPoint(latitude: 0, longitude: 0.006),
      );

      expect(maneuver!.next.kind, ManeuverKind.arrive);
      expect(maneuver.following, isNull);
      expect(maneuver.distanceMeters, closeTo(445, 5));
    });

    test('falls back to the first step without a readable geometry', () {
      final bare = RoutePlan(
        geometry: const [],
        distanceMeters: 500,
        duration: const Duration(minutes: 3),
        steps: plan.steps,
        fetchedAt: DateTime(2026, 11, 6, 14),
      );

      final maneuver = NavigationManeuver.from(bare, middle);
      expect(maneuver!.next.kind, ManeuverKind.depart);
      expect(maneuver.following?.kind, ManeuverKind.turnLeft);
      expect(maneuver.distanceMeters, closeTo(556, 5));
    });

    test('returns nothing when the route has no steps', () {
      final bare = RoutePlan(
        geometry: const [start, finish],
        distanceMeters: 1112,
        duration: const Duration(minutes: 10),
        fetchedAt: DateTime(2026, 11, 6, 14),
      );
      expect(NavigationManeuver.from(bare, start), isNull);
    });
  });

  group('RouteStep.instruction', () {
    test('names the road when there is one', () {
      expect(
        step(ManeuverKind.turnLeft, start, road: 'Bole Road').instruction,
        'Turn left onto Bole Road',
      );
      expect(
        step(ManeuverKind.uTurn, start, road: 'Africa Ave').instruction,
        'Make a U-turn onto Africa Ave',
      );
      expect(
        step(ManeuverKind.roundabout, start, road: 'Ring Road', exit: 2)
            .instruction,
        'Take exit 2 at the roundabout onto Ring Road',
      );
    });

    test('stays readable without a road name', () {
      expect(
        step(ManeuverKind.depart, start).instruction,
        'Head out',
      );
      expect(
        step(ManeuverKind.straight, start).instruction,
        'Continue',
      );
      expect(
        step(ManeuverKind.arrive, start).instruction,
        'Arrive at your destination',
      );
      expect(
        step(ManeuverKind.forkRight, start, road: 'Meskel Flower').instruction,
        'Keep right onto Meskel Flower',
      );
    });
  });

  group('camera geometry', () {
    const a = GeoPoint(latitude: 0, longitude: 0);
    const north = GeoPoint(latitude: 1, longitude: 0);
    const east = GeoPoint(latitude: 0, longitude: 1);
    const south = GeoPoint(latitude: -1, longitude: 0);
    const west = GeoPoint(latitude: 0, longitude: -1);

    test('measures compass bearing clockwise from north', () {
      expect(bearingBetween(a, north), closeTo(0, 0.01));
      expect(bearingBetween(a, east), closeTo(90, 0.01));
      expect(bearingBetween(a, south), closeTo(180, 0.01));
      expect(bearingBetween(a, west), closeTo(270, 0.01));
    });

    test('eases bearings across north without a long swing', () {
      expect(lerpBearing(350, 10, 0.5), closeTo(0, 0.01));
      expect(lerpBearing(10, 350, 0.5), closeTo(0, 0.01));
      expect(lerpBearing(350, 10, 0), closeTo(350, 0.01));
      expect(lerpBearing(350, 10, 1), closeTo(10, 0.01));
      expect(lerpBearing(90, 180, 0.5), closeTo(135, 0.01));
    });

    test('leads the camera down the road ahead of the member', () {
      final line = [start, finish];
      final lead = pointAheadOnLine(start, line, 500);

      expect(lead, isNotNull);
      expect(lead!.longitude, closeTo(0.0045, 0.0002));
      expect(lead.latitude, closeTo(0, 1e-9));
    });

    test('clamps the lead point to the end of the line', () {
      final lead = pointAheadOnLine(start, const [start, finish], 5000);
      expect(lead!.latitude, closeTo(finish.latitude, 1e-9));
      expect(lead.longitude, closeTo(finish.longitude, 1e-9));
      expect(pointAheadOnLine(start, const [start], 100), isNull);
    });
  });

  group('navigation formatting', () {
    test('reads distances like a spoken maneuver', () {
      expect(formatManeuverDistance(5), 'Now');
      expect(formatManeuverDistance(250), 'In 250 m');
      expect(formatManeuverDistance(1200), 'In 1.2 km');
      expect(formatManeuverDistance(20000), 'In 20 km');
    });

    test('spells out the trip time for the summary bar', () {
      expect(formatTripTime(const Duration(seconds: 40)), 'Under a minute');
      expect(formatTripTime(const Duration(minutes: 14)), '14 min');
      expect(formatTripTime(const Duration(minutes: 80)), '1 hr 20 min');
      expect(formatTripTime(const Duration(hours: 2)), '2 hr');
    });
  });
}
