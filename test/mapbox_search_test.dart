import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/navigation/data/mapbox_navigation_gateway.dart';

void main() {
  const addis = GeoPoint(latitude: 9.01, longitude: 38.74);

  group('MapboxNavigationGateway.searchPlaces', () {
    test(
      'queries Search Box locally and resolves venues to coordinates',
      () async {
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/search/searchbox/v1/suggest') {
            return http.Response(
              jsonEncode({
                'suggestions': [
                  {'mapbox_id': 'century', 'name': 'Century Mall'},
                  {'mapbox_id': 'gast', 'name': 'Gast Cinema'},
                ],
              }),
              200,
            );
          }

          final id = request.url.pathSegments.last;
          final features = {
            'century': _retrievedFeature(
              name: 'Century Mall',
              longitude: 38.7932,
              latitude: 8.9983,
              formatted: 'Century Mall, Bole, Addis Ababa',
              maki: 'shop',
            ),
            'gast': _retrievedFeature(
              name: 'Gast Cinema',
              longitude: 38.7501,
              latitude: 9.0102,
              formatted: 'Gast Cinema, Churchill Avenue, Addis Ababa',
              maki: 'cinema',
            ),
          };
          return http.Response(
            jsonEncode({
              'type': 'FeatureCollection',
              'features': [features[id]],
            }),
            200,
          );
        });

        final gateway = MapboxNavigationGateway(client, accessToken: 'pk.test');
        final places = await gateway.searchPlaces(
          'Century Mall',
          proximity: const GeoPoint(latitude: 9.02, longitude: 38.75),
        );

        final suggest = requests.first.url;
        expect(suggest.path, '/search/searchbox/v1/suggest');
        expect(suggest.queryParameters['q'], 'Century Mall');
        expect(suggest.queryParameters['country'], 'et');
        expect(suggest.queryParameters['bbox'], '38.60,8.84,38.95,9.12');
        expect(
          suggest.queryParameters['types'],
          'poi,address,place,neighborhood,locality',
        );
        expect(
          suggest.queryParameters['proximity'],
          '38.75,9.02',
          reason: 'Mapbox expects longitude,latitude order',
        );

        final sessionToken = suggest.queryParameters['session_token'];
        expect(sessionToken, isNotNull);
        expect(sessionToken, isNotEmpty);
        for (final retrieve in requests.skip(1)) {
          expect(
            retrieve.url.path,
            startsWith('/search/searchbox/v1/retrieve/'),
          );
          expect(retrieve.url.queryParameters['session_token'], sessionToken);
        }

        expect(places, hasLength(2));
        expect(places.first.displayName, 'Century Mall');
        expect(places.first.address, 'Bole, Addis Ababa');
        expect(places.first.categoryLabel, 'Shop');
        expect(places.first.latitude, 8.9983);
        expect(places.first.longitude, 38.7932);
        expect(
          requests.where((request) => request.url.host == 'photon.komoot.io'),
          isEmpty,
          reason: 'Photon is only a fallback',
        );
      },
    );

    test('keeps the other results when a retrieve fails', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/search/searchbox/v1/suggest') {
          return http.Response(
            jsonEncode({
              'suggestions': [
                {'mapbox_id': 'broken', 'name': 'Broken'},
                {'mapbox_id': 'edna', 'name': 'Edna Mall'},
              ],
            }),
            200,
          );
        }
        if (request.url.pathSegments.last == 'broken') {
          return http.Response('{"message": "boom"}', 500);
        }
        return http.Response(
          jsonEncode({
            'features': [
              _retrievedFeature(
                name: 'Edna Mall',
                longitude: 38.8049,
                latitude: 9.0036,
                formatted: 'Edna Mall, Bole, Addis Ababa',
              ),
            ],
          }),
          200,
        );
      });

      final gateway = MapboxNavigationGateway(client, accessToken: 'pk.test');
      final places = await gateway.searchPlaces('Edna Mall');

      expect(places, hasLength(1));
      expect(places.single.displayName, 'Edna Mall');
    });

    test(
      'falls back to Photon with an Addis bias and local filtering',
      () async {
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          if (request.url.host == 'api.mapbox.com') {
            return http.Response('{"suggestions": []}', 200);
          }

          return http.Response(
            jsonEncode({
              'features': [
                _photonFeature(
                  name: 'Century Mall',
                  longitude: 38.7932,
                  latitude: 8.9983,
                  properties: {
                    'street': 'Africa Avenue',
                    'city': 'Addis Ababa',
                    'osm_key': 'shop',
                    'osm_value': 'mall',
                  },
                ),
                _photonFeature(
                  name: 'Century Mall',
                  longitude: -118.4,
                  latitude: 34.05,
                  properties: {'city': 'Los Angeles', 'osm_value': 'mall'},
                ),
              ],
            }),
            200,
          );
        });

        final gateway = MapboxNavigationGateway(client, accessToken: 'pk.test');
        final places = await gateway.searchPlaces('Century Mall');

        expect(places, hasLength(1));
        expect(places.single.displayName, 'Century Mall');
        expect(places.single.address, 'Africa Avenue, Addis Ababa');
        expect(places.single.category, 'mall');
        expect(places.single.latitude, 8.9983);
        expect(places.single.longitude, 38.7932);

        final photon = requests.singleWhere(
          (request) => request.url.host == 'photon.komoot.io',
        );
        expect(photon.url.path, '/api/');
        expect(photon.url.queryParameters['q'], 'Century Mall');
        expect(photon.url.queryParameters['lat'], '9.01000');
        expect(photon.url.queryParameters['lon'], '38.74000');
        expect(photon.headers['User-Agent'], contains('Pathfinders'));
      },
    );

    test('uses the live fix to bias Photon when one is available', () async {
      final photonRequest = <http.Request>[];
      final client = MockClient((request) async {
        if (request.url.host == 'api.mapbox.com') {
          return http.Response('{"suggestions": []}', 200);
        }
        photonRequest.add(request);
        return http.Response(
          jsonEncode({
            'features': [
              _photonFeature(
                name: 'Local Cafe',
                longitude: 38.78,
                latitude: 9.02,
                properties: {'city': 'Addis Ababa', 'osm_value': 'cafe'},
              ),
            ],
          }),
          200,
        );
      });

      final gateway = MapboxNavigationGateway(client, accessToken: 'pk.test');
      await gateway.searchPlaces('Local Cafe', proximity: addis);

      expect(photonRequest.single.url.queryParameters['lat'], '9.01000');
      expect(photonRequest.single.url.queryParameters['lon'], '38.74000');
    });

    test('returns nothing when both providers have no answer', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'api.mapbox.com') {
          return http.Response('{"suggestions": []}', 200);
        }
        return http.Response('unavailable', 503);
      });

      final gateway = MapboxNavigationGateway(client, accessToken: 'pk.test');

      expect(await gateway.searchPlaces('Nowhere At All'), isEmpty);
    });

    test('skips the network for one-letter queries', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response('{}', 200);
      });

      final gateway = MapboxNavigationGateway(client, accessToken: 'pk.test');

      expect(await gateway.searchPlaces(' C '), isEmpty);
      expect(calls, 0);
    });
  });
}

Map<String, Object?> _retrievedFeature({
  required String name,
  required double longitude,
  required double latitude,
  String? formatted,
  String? maki,
}) {
  return {
    'type': 'Feature',
    'geometry': {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    },
    'properties': {'name': name, 'place_formatted': ?formatted, 'maki': ?maki},
  };
}

Map<String, Object?> _photonFeature({
  required String name,
  required double longitude,
  required double latitude,
  required Map<String, Object?> properties,
}) {
  return {
    'type': 'Feature',
    'geometry': {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    },
    'properties': {'name': name, ...properties},
  };
}
