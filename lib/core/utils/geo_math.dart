import 'dart:math' as math;

/// Great-circle distance between two coordinates, in metres.
double distanceMeters({
  required double latA,
  required double lonA,
  required double latB,
  required double lonB,
}) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _radians(latB - latA);
  final dLon = _radians(lonB - lonA);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(latA)) *
          math.cos(_radians(latB)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;
