import '../../location/domain/geo_point.dart';

/// A route from one member's live position to the shared destination.
class RoutePlan {
  const RoutePlan({
    required this.geometry,
    required this.distanceMeters,
    required this.duration,
    required this.fetchedAt,
  });

  final List<GeoPoint> geometry;
  final double distanceMeters;
  final Duration duration;

  /// When the route was calculated. ETA is this plus [duration], so it keeps
  /// ageing honestly on screen without another request.
  final DateTime fetchedAt;

  DateTime get eta => fetchedAt.add(duration);

  bool get hasArrived => distanceMeters <= 40;
}
