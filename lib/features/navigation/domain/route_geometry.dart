import 'dart:math' as math;

import '../../location/domain/geo_point.dart';

/// Great-circle distance in metres. Used only to decide when a cached route is
/// stale, so the flat-earth shortcut is plenty.
double distanceMeters(GeoPoint a, GeoPoint b) {
  const earthRadius = 6371000.0;
  final dLat = _radians(b.latitude - a.latitude);
  final dLon = _radians(b.longitude - a.longitude);
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final sinLat = math.sin(dLat / 2);
  final sinLon = math.sin(dLon / 2);
  final h = sinLat * sinLat +
      sinLon * sinLon * math.cos(lat1) * math.cos(lat2);
  return 2 * earthRadius * math.asin(math.sqrt(h));
}

/// Shortest distance from [point] to any segment of [line], in metres.
///
/// When the line has fewer than two points this falls back to the distance to
/// the single point (or infinity for an empty line).
double distanceToLineMeters(GeoPoint point, List<GeoPoint> line) {
  if (line.isEmpty) return double.infinity;
  if (line.length == 1) return distanceMeters(point, line.first);

  var best = double.infinity;
  for (var i = 0; i < line.length - 1; i++) {
    final candidate = _distanceToSegment(point, line[i], line[i + 1]);
    if (candidate < best) best = candidate;
  }
  return best;
}

double _distanceToSegment(GeoPoint p, GeoPoint a, GeoPoint b) {
  // Project onto a local flat plane: accurate enough over a route segment.
  final latRef = _radians((a.latitude + b.latitude) / 2);
  final bx = _radians(b.longitude - a.longitude) * math.cos(latRef) * 6371000;
  final by = _radians(b.latitude - a.latitude) * 6371000;
  final px = _radians(p.longitude - a.longitude) * math.cos(latRef) * 6371000;
  final py = _radians(p.latitude - a.latitude) * 6371000;

  final lengthSquared = bx * bx + by * by;
  if (lengthSquared == 0) return math.sqrt(px * px + py * py);

  final t = (px * bx + py * by) / lengthSquared;
  final clamped = t.clamp(0.0, 1.0);
  final ex = px - bx * clamped;
  final ey = py - by * clamped;
  return math.sqrt(ex * ex + ey * ey);
}

double _radians(double degrees) => degrees * math.pi / 180;
