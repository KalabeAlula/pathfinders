import '../../location/domain/geo_point.dart';
import 'navigation_destination.dart';
import 'route_geometry.dart';

/// How close a member must be to the shared destination to count as arrived.
const arrivalRadiusMeters = 40.0;

/// A fix this vague cannot tell 40 m from the next block, so it never arrives.
const arrivalAccuracyCeilingMeters = 100.0;

bool isWithinArrivalRadius(
  GeoPoint current,
  GeoPoint destination, {
  double accuracyMeters = 0,
}) {
  if (accuracyMeters > arrivalAccuracyCeilingMeters) return false;
  return distanceMeters(current, destination) <= arrivalRadiusMeters;
}

/// True only when every member has a fix and all of those fixes are inside the
/// arrival radius.
bool allMembersWithinArrivalRadius(
  Iterable<GeoPoint?> memberPoints,
  GeoPoint destination,
) {
  var count = 0;
  for (final point in memberPoints) {
    if (point == null) return false;
    if (distanceMeters(point, destination) > arrivalRadiusMeters) return false;
    count++;
  }
  return count > 0;
}

/// Identity of one trip to a destination.
///
/// Setting a destination again produces a new timestamp, so the arrival
/// announcement happens once per trip rather than once per pin forever.
String destinationTripKey(NavigationDestination destination) {
  final lat = destination.latitude.toStringAsFixed(5);
  final lon = destination.longitude.toStringAsFixed(5);
  return '${destination.updatedAt.toUtc().toIso8601String()}|$lat,$lon';
}
