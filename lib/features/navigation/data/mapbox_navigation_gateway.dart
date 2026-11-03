import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../location/domain/geo_point.dart';
import '../domain/navigation_failure.dart';
import '../domain/navigation_gateway.dart';
import '../domain/place_suggestion.dart';
import '../domain/route_plan.dart';
import 'polyline_decoder.dart';

/// Thin client for Mapbox Directions v5, Search Box v1, and reverse
/// Geocoding v5.
///
/// Only the public `pk.` token is used. Routes use the traffic-aware driving
/// profile so ETAs reflect the road, not straight-line distance. Place search
/// is scoped to Addis Ababa, with an OpenStreetMap Photon fallback for venues
/// Mapbox has not indexed.
class MapboxNavigationGateway implements NavigationGateway {
  MapboxNavigationGateway(this._client, {required String accessToken})
    : _token = accessToken;

  final http.Client _client;
  final String _token;

  static const _host = 'api.mapbox.com';
  static const _profile = 'driving-traffic';

  /// Addis Ababa, used to keep Mapbox results local and to bias Photon.
  static const _addisBbox = '38.60,8.84,38.95,9.12';
  static const _addisCenter = GeoPoint(latitude: 9.01, longitude: 38.74);

  /// Rough Addis metro radius in degrees for pruning Photon's global matches.
  static const _biasRadiusDegrees = 0.75;

  static const _searchTypes = 'poi,address,place,neighborhood,locality';

  final Random _random = Random();

  @override
  bool get isConfigured => _token.trim().isNotEmpty;

  @override
  Future<RoutePlan> route({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    _ensureConfigured();

    final coordinates =
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final uri = Uri.https(
      _host,
      '/directions/v5/mapbox/$_profile/$coordinates',
      {
        'alternatives': 'false',
        'geometries': 'polyline',
        'overview': 'full',
        'steps': 'false',
        'access_token': _token,
      },
    );

    final body = await _getJson(uri);
    final routes = body['routes'];
    if (routes is! List || routes.isEmpty) {
      throw const NavigationFailure('Mapbox could not find a route there.');
    }

    final first = routes.first;
    if (first is! Map<String, dynamic> || first['geometry'] is! String) {
      throw const NavigationFailure('Mapbox returned an unreadable route.');
    }

    final seconds = (first['duration'] as num?)?.toDouble() ?? 0;
    return RoutePlan(
      geometry: decodePolyline(first['geometry'] as String),
      distanceMeters: (first['distance'] as num?)?.toDouble() ?? 0,
      duration: Duration(seconds: seconds.round()),
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    GeoPoint? proximity,
  }) async {
    final clean = query.trim();
    if (clean.length < 2) return const [];
    _ensureConfigured();

    final sessionToken = _newSessionToken();
    final uri = Uri.https(_host, '/search/searchbox/v1/suggest', {
      'q': clean,
      'language': 'en',
      'limit': '6',
      'types': _searchTypes,
      'country': 'et',
      'bbox': _addisBbox,
      'session_token': sessionToken,
      'access_token': _token,
      if (proximity != null)
        'proximity': '${proximity.longitude},${proximity.latitude}',
    });

    final body = await _getJson(uri);
    final suggestions = body['suggestions'];
    final ids = <String>[
      if (suggestions is List)
        for (final suggestion in suggestions)
          if (suggestion is Map && suggestion['mapbox_id'] is String)
            suggestion['mapbox_id'] as String,
    ];

    final features = await Future.wait([
      for (final id in ids.take(6)) _retrieveFeature(id, sessionToken),
    ]);
    final places = [
      for (final feature in features) ?_placeFromSearchBoxFeature(feature),
    ];

    // Mapbox's commercial index is thin in Addis; OSM Photon fills the gaps.
    if (places.isNotEmpty) return places;
    return _photonSearch(clean, proximity);
  }

  @override
  Future<String?> reverseGeocode(GeoPoint point) async {
    _ensureConfigured();

    final uri = Uri.https(
      _host,
      '/geocoding/v5/mapbox.places/'
      '${point.longitude},${point.latitude}.json',
      {
        'limit': '1',
        'types': 'address,poi,place,locality,neighborhood',
        'access_token': _token,
      },
    );

    final body = await _getJson(uri);
    final features = body['features'];
    if (features is! List || features.isEmpty) return null;

    final first = features.first;
    if (first is! Map<String, dynamic>) return null;
    final name = first['place_name'];
    if (name is! String || name.trim().isEmpty) return null;
    return name.trim();
  }

  /// Suggest results carry no coordinates, so each one is resolved to a
  /// GeoJSON feature. A single failed lookup must not sink the whole list.
  Future<Object?> _retrieveFeature(String mapboxId, String sessionToken) async {
    final uri = Uri.https(
      _host,
      '/search/searchbox/v1/retrieve/${Uri.encodeComponent(mapboxId)}',
      {'session_token': sessionToken, 'access_token': _token},
    );

    try {
      final body = await _getJson(uri);
      final features = body['features'];
      if (features is! List || features.isEmpty) return null;
      return features.first;
    } on NavigationFailure {
      return null;
    }
  }

  Future<List<PlaceSuggestion>> _photonSearch(
    String query,
    GeoPoint? proximity,
  ) async {
    final bias = proximity ?? _addisCenter;
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'lat': bias.latitude.toStringAsFixed(5),
      'lon': bias.longitude.toStringAsFixed(5),
      'limit': '6',
      'lang': 'en',
    });

    final body = await _getOptionalJson(
      uri,
      headers: const {'User-Agent': 'Pathfinders/1.0 (Addis Ababa)'},
    );
    if (body == null) return const [];

    final features = body['features'];
    if (features is! List) return const [];

    return [
      for (final feature in features) ?_placeFromPhotonFeature(feature, bias),
    ];
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const NavigationFailure('Mapbox returned an unexpected reply.');
      }
      if (response.statusCode != 200) {
        throw NavigationFailure(
          _messageFor(response.statusCode, decoded['message']),
          code: '${response.statusCode}',
        );
      }
      return decoded;
    } on NavigationFailure {
      rethrow;
    } on Exception {
      throw const NavigationFailure(
        'Could not reach Mapbox. Check your connection and try again.',
      );
    }
  }

  /// Best-effort lookup for optional providers; null means "no answer".
  Future<Map<String, dynamic>?> _getOptionalJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Exception {
      return null;
    }
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const NavigationFailure(
        'Add your Mapbox public token to turn on routing.',
      );
    }
  }

  String _newSessionToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static String _messageFor(int status, Object? message) {
    if (status == 401 || status == 403) {
      return 'Mapbox rejected the access token. Check MAPBOX_ACCESS_TOKEN '
          'and make sure it allows Directions, Geocoding, and Search Box.';
    }
    if (status == 429) {
      return 'Mapbox is rate-limiting requests right now. Try again in a '
          'moment.';
    }
    if (message is String && message.trim().isNotEmpty) {
      return 'Mapbox: ${message.trim()}';
    }
    return 'Mapbox could not complete that request.';
  }
}

PlaceSuggestion? _placeFromSearchBoxFeature(Object? raw) {
  if (raw is! Map) return null;

  final geometry = raw['geometry'];
  if (geometry is! Map) return null;
  final coordinates = geometry['coordinates'];
  if (coordinates is! List || coordinates.length < 2) return null;
  final longitude = coordinates[0];
  final latitude = coordinates[1];
  if (longitude is! num || latitude is! num) return null;

  final properties = raw['properties'];
  final props = properties is Map ? properties : const {};

  final name = _text(props['name']) ?? _text(props['place_formatted']);
  if (name == null) return null;

  final formatted =
      _text(props['place_formatted']) ?? _text(props['full_address']);
  final address = _addressFromFormatted(formatted, name);

  return PlaceSuggestion(
    label: address == null ? name : '$name, $address',
    name: name,
    address: address,
    // maki is the specific icon key, matching the map's labels.
    category: _text(props['maki']) ?? _firstText(props['poi_category']),
    maki: _text(props['maki']),
    longitude: longitude.toDouble(),
    latitude: latitude.toDouble(),
  );
}

PlaceSuggestion? _placeFromPhotonFeature(Object? raw, GeoPoint bias) {
  if (raw is! Map) return null;

  final geometry = raw['geometry'];
  if (geometry is! Map) return null;
  final coordinates = geometry['coordinates'];
  if (coordinates is! List || coordinates.length < 2) return null;
  final longitude = coordinates[0];
  final latitude = coordinates[1];
  if (longitude is! num || latitude is! num) return null;

  final point = GeoPoint(
    latitude: latitude.toDouble(),
    longitude: longitude.toDouble(),
  );
  if (!_withinBias(point, bias)) return null;

  final properties = raw['properties'];
  if (properties is! Map) return null;

  final name = _text(properties['name']) ?? _text(properties['street']);
  if (name == null) return null;

  final street = _text(properties['street']);
  final houseNumber = _text(properties['housenumber']);
  final city = _text(properties['city']) ?? _text(properties['district']);

  final streetLine = street == null || street == name
      ? null
      : [?houseNumber, street].join(' ');
  final address = [streetLine, city].nonNulls.join(', ');
  final resolvedAddress = address.isEmpty ? null : address;

  final osmValue = _text(properties['osm_value']);
  final category = osmValue == null || osmValue == 'yes'
      ? _text(properties['type'])
      : osmValue;

  return PlaceSuggestion(
    label: resolvedAddress == null ? name : '$name, $resolvedAddress',
    name: name,
    address: resolvedAddress,
    category: category,
    longitude: point.longitude,
    latitude: point.latitude,
  );
}

bool _withinBias(GeoPoint point, GeoPoint bias) {
  return (point.latitude - bias.latitude).abs() <=
          MapboxNavigationGateway._biasRadiusDegrees &&
      (point.longitude - bias.longitude).abs() <=
          MapboxNavigationGateway._biasRadiusDegrees;
}

String? _addressFromFormatted(String? formatted, String name) {
  if (formatted == null || formatted == name) return null;
  final prefix = '$name, ';
  final address = formatted.startsWith(prefix)
      ? formatted.substring(prefix.length).trim()
      : formatted;
  return address.isEmpty ? null : address;
}

String? _text(Object? value) {
  final text = value is String ? value.trim() : null;
  return text == null || text.isEmpty ? null : text;
}

String? _firstText(Object? value) {
  if (value is List) {
    for (final item in value) {
      final text = _text(item);
      if (text != null) return text;
    }
  }
  return _text(value);
}
