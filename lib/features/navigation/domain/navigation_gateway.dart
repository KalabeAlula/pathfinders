import '../../location/domain/geo_point.dart';
import 'place_suggestion.dart';
import 'route_plan.dart';

abstract interface class NavigationGateway {
  bool get isConfigured;

  Future<RoutePlan> route({required GeoPoint from, required GeoPoint to});

  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    GeoPoint? proximity,
  });
}
