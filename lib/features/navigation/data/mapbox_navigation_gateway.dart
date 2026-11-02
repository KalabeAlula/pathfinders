import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../location/domain/geo_point.dart';
import '../domain/navigation_failure.dart';
import '../domain/navigation_gateway.dart';
import '../domain/place_suggestion.dart';
import '../domain/route_plan.dart';
import 'polyline_decoder.dart';

/// Thin client for Mapbox Directions v5 and Geocoding v5.
///
/// Only the public `pk.` token is used. Routes use the traffic-aware driving
/// profile so ETAs reflect the road, not straight-line distance.
class MapboxNavigationGateway implements NavigationGateway {
  MapboxNavigationGateway(this._client, {required String accessToken})
    : _token = accessToken;

  final http.Client _client;
  final String _token;

  static const _host = 'api.mapbox.com';
  static const _profile = 'driving-traffic';

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

    final encoded = Uri.encodeComponent(clean);
    final uri = Uri.https(_host, '/geocoding/v5/mapbox.places/$encoded.json', {
      'limit': '6',
      'types': 'poi,address,place,locality,neighborhood',
      'autocomplete': 'true',
      'access_token': _token,
      if (proximity != null)
        'proximity': '${proximity.longitude},${proximity.latitude}',
    });

    final body = await _getJson(uri);
    final features = body['features'];
    if (features is! List) return const [];

    return [
      for (final feature in features) ?PlaceSuggestion.fromFeature(feature),
    ];
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

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const NavigationFailure(
        'Add your Mapbox public token to turn on routing.',
      );
    }
  }

  static String _messageFor(int status, Object? message) {
    if (status == 401 || status == 403) {
      return 'Mapbox rejected the access token. Check MAPBOX_ACCESS_TOKEN '
          'and make sure it allows Directions and Geocoding.';
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
