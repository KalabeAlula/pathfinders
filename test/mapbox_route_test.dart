import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/navigation/data/mapbox_navigation_gateway.dart';
import 'package:pathfinders/features/navigation/domain/route_step.dart';

void main() {
  const from = GeoPoint(latitude: 9.01, longitude: 38.74);
  const to = GeoPoint(latitude: 8.99, longitude: 38.79);

  MapboxNavigationGateway gatewayFor(http.Response response) {
    final client = MockClient((_) async => response);
    return MapboxNavigationGateway(client, accessToken: 'pk.test');
  }

  group('MapboxNavigationGateway.route', () {
    test('requests turn-by-turn steps and parses them', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'routes': [
              {
                'distance': 1200.5,
                'duration': 300.4,
                'geometry': r'_p~iF~ps|U_ulLnnqC_mqNvxq`@',
                'steps': [
                  {
                    'maneuver': {
                      'type': 'depart',
                      'modifier': 'right',
                      'location': [38.74, 9.01],
                    },
                    'name': 'Bole Road',
                    'distance': 200,
                    'duration': 40.2,
                  },
                  {
                    'maneuver': {
                      'type': 'turn',
                      'modifier': 'left',
                      'location': [38.741, 9.011],
                    },
                    'name': 'Africa Ave',
                    'distance': 300,
                    'duration': 60,
                  },
                  {
                    'maneuver': {
                      'type': 'roundabout',
                      'modifier': 'right',
                      'exit': 2,
                      'location': [38.742, 9.012],
                    },
                    'name': '',
                    'ref': 'Ring Road',
                    'distance': 500,
                    'duration': 100,
                  },
                  {
                    'maneuver': {
                      'type': 'fork',
                      'modifier': 'slight left',
                      'location': [38.743, 9.013],
                    },
                    'name': 'Meskel Flower',
                    'distance': 200,
                    'duration': 100,
                  },
                  {
                    'maneuver': {
                      'type': 'arrive',
                      'location': [38.744, 9.014],
                    },
                    'name': 'Century Mall',
                    'distance': 0,
                    'duration': 0,
                  },
                ],
              },
            ],
          }),
          200,
        );
      });

      final gateway = MapboxNavigationGateway(client, accessToken: 'pk.test');
      final plan = await gateway.route(from: from, to: to);

      final query = requests.single.url.queryParameters;
      expect(query['steps'], 'true');
      expect(
        requests.single.url.path,
        '/directions/v5/mapbox/driving-traffic/38.74,9.01;38.79,8.99',
      );

      expect(plan.steps, hasLength(5));
      expect(plan.steps.map((step) => step.kind), [
        ManeuverKind.depart,
        ManeuverKind.turnLeft,
        ManeuverKind.roundabout,
        ManeuverKind.forkLeft,
        ManeuverKind.arrive,
      ]);
      expect(plan.steps[1].roadName, 'Africa Ave');
      expect(plan.steps[1].distanceMeters, 300);
      expect(plan.steps[1].duration, const Duration(seconds: 60));
      expect(plan.steps[1].location.latitude, closeTo(9.011, 1e-9));
      expect(plan.steps[1].location.longitude, closeTo(38.741, 1e-9));
      expect(plan.steps[1].instruction, 'Turn left onto Africa Ave');
      expect(plan.steps[2].exitNumber, 2);
      expect(plan.steps[2].roadName, 'Ring Road');
    });

    test('survives a response without steps', () async {
      final gateway = gatewayFor(
        http.Response(
          jsonEncode({
            'routes': [
              {
                'distance': 100,
                'duration': 20,
                'geometry': r'_p~iF~ps|U_ulLnnqC_mqNvxq`@',
              },
            ],
          }),
          200,
        ),
      );

      final plan = await gateway.route(from: from, to: to);
      expect(plan.steps, isEmpty);
    });
  });
}
