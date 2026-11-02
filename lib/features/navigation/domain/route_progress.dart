import '../../location/domain/geo_point.dart';
import 'route_geometry.dart';
import 'route_plan.dart';

/// Where a member sits on their route right now.
///
/// Derived locally from the cached polyline and the latest fix, so the numbers
/// shrink between Directions API refreshes instead of jumping on every reroute.
class RouteProgress {
  const RouteProgress({
    required this.remainingMeters,
    required this.remaining,
    required this.arrival,
    required this.arrived,
  });

  factory RouteProgress.from(
    RoutePlan plan,
    GeoPoint current, {
    DateTime? now,
  }) {
    final location = progressAlongLine(current, plan.geometry);
    final fraction = location.total <= 0
        ? 0.0
        : ((location.total - location.travelled) / location.total).clamp(
            0.0,
            1.0,
          );

    final remainingMeters = plan.distanceMeters * fraction;
    final remaining = Duration(
      seconds: (plan.duration.inSeconds * fraction).round(),
    );
    final reference = now ?? DateTime.now();

    return RouteProgress(
      remainingMeters: remainingMeters,
      remaining: remaining,
      arrival: reference.add(remaining),
      arrived: remainingMeters <= _arrivalThresholdMeters,
    );
  }

  static const _arrivalThresholdMeters = 40.0;

  final double remainingMeters;
  final Duration remaining;
  final DateTime arrival;
  final bool arrived;
}
