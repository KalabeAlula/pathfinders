import '../../location/domain/geo_point.dart';
import 'route_geometry.dart' as geo;
import 'route_plan.dart';
import 'route_step.dart';

/// What the maneuver banner should show right now: the next turn, how far
/// away it is, and the move after that as a preview.
class NavigationManeuver {
  const NavigationManeuver({
    required this.next,
    required this.following,
    required this.distanceMeters,
  });

  final RouteStep next;

  /// The maneuver after [next], when the route has one.
  final RouteStep? following;

  /// Distance from the member's fix to [next]'s maneuver point, measured
  /// along the route.
  final double distanceMeters;

  /// Reads the route at [current]. The next move is the first step whose
  /// maneuver point is still ahead, so a step already being driven is not
  /// announced again.
  static NavigationManeuver? from(RoutePlan plan, GeoPoint current) {
    final steps = plan.steps;
    if (steps.isEmpty) return null;

    final geometry = plan.geometry;
    if (geometry.length < 2) {
      return NavigationManeuver(
        next: steps.first,
        following: steps.length > 1 ? steps[1] : null,
        distanceMeters: geo.distanceMeters(current, steps.first.location),
      );
    }

    final travelled = geo.progressAlongLine(current, geometry).travelled;
    final starts = <double>[];
    var previousStart = 0.0;
    for (final step in steps) {
      // Projections can tie or wobble backwards where steps share a vertex;
      // clamping keeps the cumulative order the driver actually follows.
      final projected = geo
          .progressAlongLine(step.location, geometry)
          .travelled;
      final start = projected < previousStart ? previousStart : projected;
      starts.add(start);
      previousStart = start;
    }

    var index = steps.length - 1;
    for (var i = 0; i < steps.length; i++) {
      if (starts[i] > travelled + 2) {
        index = i;
        break;
      }
    }

    final remaining = starts[index] - travelled;
    return NavigationManeuver(
      next: steps[index],
      following: index + 1 < steps.length ? steps[index + 1] : null,
      distanceMeters: remaining < 0 ? 0 : remaining,
    );
  }
}
