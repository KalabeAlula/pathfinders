import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../location/domain/geo_point.dart';

/// A venue found under a map tap: a Standard POI or an extruded building.
class VenueHit {
  const VenueHit({
    required this.point,
    this.name,
    this.category,
    this.maki,
    this.feature,
    this.isBuilding = false,
  });

  final GeoPoint point;
  final String? name;

  /// Raw POI class, or `building` for footprints.
  final String? category;
  final String? maki;

  /// The raw feature, kept so the map can highlight it.
  final FeaturesetFeature? feature;
  final bool isBuilding;

  /// A human label such as "Cafe" or "Building".
  String? get categoryLabel {
    if (isBuilding) return 'Building';
    final raw = category?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'poi') return null;
    final words = raw.replaceAll(RegExp('[-_]'), ' ').trim();
    if (words.isEmpty) return null;
    return words
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

/// Maps a Maki/class string to a Material icon for the venue card.
IconData venueIcon({String? category, String? maki}) {
  final key = '${category ?? ''} ${maki ?? ''}'.toLowerCase();
  if (key.contains('building') ||
      key.contains('apartment') ||
      key.contains('house')) {
    return Icons.apartment_rounded;
  }
  if (key.contains('cafe') || key.contains('coffee')) {
    return Icons.local_cafe_rounded;
  }
  if (key.contains('restaurant') ||
      key.contains('food') ||
      key.contains('fast')) {
    return Icons.restaurant_rounded;
  }
  if (key.contains('bar') || key.contains('pub') || key.contains('night')) {
    return Icons.local_bar_rounded;
  }
  if (key.contains('cinema') ||
      key.contains('movie') ||
      key.contains('theatre') ||
      key.contains('theater')) {
    return Icons.theater_comedy_rounded;
  }
  if (key.contains('shop') ||
      key.contains('store') ||
      key.contains('mall') ||
      key.contains('market')) {
    return Icons.storefront_rounded;
  }
  if (key.contains('hotel') || key.contains('lodging')) {
    return Icons.hotel_rounded;
  }
  if (key.contains('fuel') || key.contains('gas') || key.contains('petrol')) {
    return Icons.local_gas_station_rounded;
  }
  if (key.contains('transit') ||
      key.contains('bus') ||
      key.contains('train') ||
      key.contains('station')) {
    return Icons.directions_transit_rounded;
  }
  if (key.contains('bank') || key.contains('atm')) {
    return Icons.account_balance_rounded;
  }
  if (key.contains('hospital') ||
      key.contains('clinic') ||
      key.contains('pharmacy') ||
      key.contains('doctor')) {
    return Icons.local_hospital_rounded;
  }
  if (key.contains('school') ||
      key.contains('university') ||
      key.contains('college')) {
    return Icons.school_rounded;
  }
  if (key.contains('park') || key.contains('garden')) {
    return Icons.park_rounded;
  }
  return Icons.place_rounded;
}

/// Finds the best POI or building under [touch].
///
/// POIs always win over the building behind them, and a slightly padded tap
/// area makes small cafe/cinema icons comfortable to hit.
Future<VenueHit?> venueAt(
  MapboxMap map,
  ScreenCoordinate touch,
  Point tap,
) async {
  const slop = 14.0;
  final geometry = RenderedQueryGeometry.fromScreenBox(
    ScreenBox(
      min: ScreenCoordinate(x: touch.x - slop, y: touch.y - slop),
      max: ScreenCoordinate(x: touch.x + slop, y: touch.y + slop),
    ),
  );

  try {
    final pois = await map.queryRenderedFeaturesForFeatureset(
      featureset: StandardPOIs(),
      geometry: geometry,
    );
    final poi = _nearest(pois, tap);
    final point = poi == null ? null : _pointOf(poi);
    if (poi != null && point != null) {
      return VenueHit(
        point: point,
        name: _text(poi.properties['name']) ?? _text(poi.properties['name_en']),
        category:
            _text(poi.properties['maki']) ??
            _text(poi.properties['class']) ??
            _text(poi.properties['group']),
        maki: _text(poi.properties['maki']),
        feature: poi,
      );
    }
  } catch (_) {
    // Featureset queries are unavailable while the style is reloading.
  }

  try {
    final buildings = await map.queryRenderedFeaturesForFeatureset(
      featureset: StandardBuildings(),
      geometry: geometry,
    );
    final building = _buildingAt(buildings, tap);
    final point = building == null ? null : _pointOf(building);
    if (building != null && point != null) {
      return VenueHit(
        point: point,
        name: _text(building.properties['name']),
        category: 'building',
        feature: building,
        isBuilding: true,
      );
    }
  } catch (_) {
    // Same as above: a style swap invalidates the query for a moment.
  }

  return null;
}

String? _text(Object? value) {
  final text = value is String ? value.trim() : null;
  return text == null || text.isEmpty ? null : text;
}

/// The feature whose anchor is closest to the tap, so overlapping icons resolve
/// predictably instead of depending on render order.
FeaturesetFeature? _nearest(List<FeaturesetFeature> features, Point tap) {
  final tapLng = tap.coordinates.lng.toDouble();
  final tapLat = tap.coordinates.lat.toDouble();
  final lngScale = math.cos(tapLat * math.pi / 180);

  FeaturesetFeature? best;
  var bestScore = double.infinity;
  for (final feature in features) {
    final point = _pointOf(feature);
    if (point == null) continue;
    final dx = (point.longitude - tapLng) * lngScale;
    final dy = point.latitude - tapLat;
    final score = dx * dx + dy * dy;
    if (score < bestScore) {
      bestScore = score;
      best = feature;
    }
  }
  return best;
}

/// The footprint whose polygon contains the tap, falling back to the nearest
/// centroid when the finger landed just beside the geometry.
FeaturesetFeature? _buildingAt(List<FeaturesetFeature> features, Point tap) {
  final longitude = tap.coordinates.lng.toDouble();
  final latitude = tap.coordinates.lat.toDouble();
  for (final feature in features) {
    if (_contains(feature, longitude, latitude)) return feature;
  }
  return _nearest(features, tap);
}

bool _contains(FeaturesetFeature feature, double longitude, double latitude) {
  final coordinates = feature.geometry['coordinates'];
  if (coordinates is! List) return false;

  final polygons = switch (feature.geometry['type']) {
    'Polygon' => [coordinates],
    'MultiPolygon' => coordinates,
    _ => const <Object?>[],
  };

  for (final polygon in polygons) {
    if (polygon is! List || polygon.isEmpty) continue;
    final ring = polygon.first;
    if (ring is List && _inRing(ring, longitude, latitude)) return true;
  }
  return false;
}

/// Ray casting on the exterior ring; holes are ignored because tapping a hole
/// is overwhelmingly a tap on the courtyard beside the building anyway.
bool _inRing(List<Object?> ring, double longitude, double latitude) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i];
    final b = ring[j];
    if (a is! List || b is! List || a.length < 2 || b.length < 2) continue;
    final ax = a[0];
    final ay = a[1];
    final bx = b[0];
    final by = b[1];
    if (ax is! num || ay is! num || bx is! num || by is! num) continue;

    final xi = ax.toDouble();
    final yi = ay.toDouble();
    final xj = bx.toDouble();
    final yj = by.toDouble();
    final crosses =
        ((yi > latitude) != (yj > latitude)) &&
        (longitude < (xj - xi) * (latitude - yi) / (yj - yi) + xi);
    if (crosses) inside = !inside;
  }
  return inside;
}

GeoPoint? _pointOf(FeaturesetFeature feature) {
  final type = feature.geometry['type'];
  final coordinates = feature.geometry['coordinates'];

  if (type == 'Point' && coordinates is List && coordinates.length >= 2) {
    return _geo(coordinates[0], coordinates[1]);
  }

  if (coordinates is List) {
    var longitude = 0.0;
    var latitude = 0.0;
    var count = 0;

    void visit(Object? node) {
      if (node is! List) return;
      if (node.length >= 2 && node[0] is num && node[1] is num) {
        longitude += (node[0] as num).toDouble();
        latitude += (node[1] as num).toDouble();
        count++;
        return;
      }
      for (final child in node) {
        visit(child);
      }
    }

    visit(coordinates);
    if (count > 0) {
      return GeoPoint(latitude: latitude / count, longitude: longitude / count);
    }
  }

  return null;
}

GeoPoint? _geo(Object? longitude, Object? latitude) {
  if (longitude is! num || latitude is! num) return null;
  return GeoPoint(
    latitude: latitude.toDouble(),
    longitude: longitude.toDouble(),
  );
}
