import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/location/presentation/widgets/map_circle_view.dart';
import 'package:pathfinders/features/location/presentation/widgets/mapbox_live_annotations.dart';

MapMemberPin _pin(String id, double latitude, double longitude) => MapMemberPin(
  id: id,
  initials: 'KA',
  avatarId: 'fox',
  latitude: latitude,
  longitude: longitude,
  accent: const Color(0xFFB86B4F),
  background: const Color(0xFFFFFBF5),
  approximate: false,
  isCurrentUser: id == 'you',
);

void main() {
  test('overview covers every member, route point and the destination', () {
    final overview = MapCircleView(
      pins: [_pin('you', 9.010, 38.760), _pin('peer', 9.040, 38.800)],
      lines: [
        const MapRouteLine(
          memberId: 'you',
          points: [
            GeoPoint(latitude: 9.010, longitude: 38.760),
            GeoPoint(latitude: 9.025, longitude: 38.785),
            GeoPoint(latitude: 9.040, longitude: 38.800),
          ],
          color: Color(0xFFB86B4F),
          width: 6,
        ),
      ],
      routes: const [],
      colors: const {},
      locatedCount: 2,
      pausedCount: 0,
    );
    const destination = GeoPoint(latitude: 9.041, longitude: 38.802);

    final points = routeOverviewPoints(view: overview, destination: destination);

    expect(points, hasLength(6));
    expect(
      points.map((point) => (point.latitude, point.longitude)),
      containsAll(<(double, double)>[
        (9.010, 38.760),
        (9.040, 38.800),
        (9.025, 38.785),
        (9.041, 38.802),
      ]),
    );
  });

  test('an empty circle still includes the destination', () {
    final points = routeOverviewPoints(
      view: const MapCircleView(
        pins: [],
        lines: [],
        routes: [],
        colors: {},
        locatedCount: 0,
        pausedCount: 0,
      ),
      destination: const GeoPoint(latitude: 9.041, longitude: 38.802),
    );

    expect(points, hasLength(1));
    expect(points.single.latitude, 9.041);
    expect(points.single.longitude, 38.802);
  });
}
