import '../../location/domain/geo_point.dart';
import '../domain/navigation_destination.dart';
import '../domain/route_plan.dart';

/// A member's current route to the shared destination.
class MemberRoute {
  const MemberRoute({
    required this.memberId,
    required this.plan,
    required this.origin,
    required this.computedAt,
  });

  final String memberId;
  final RoutePlan plan;

  /// The fix the route was calculated from.
  final GeoPoint origin;
  final DateTime computedAt;
}

class NavigationState {
  const NavigationState({
    this.destination,
    this.routes = const {},
    this.loadingMemberIds = const {},
    this.error,
    this.isConfigured = false,
  });

  final NavigationDestination? destination;
  final Map<String, MemberRoute> routes;
  final Set<String> loadingMemberIds;
  final String? error;

  /// False when no Mapbox public token was compiled in.
  final bool isConfigured;

  bool get isActive => destination != null;

  MemberRoute? routeFor(String memberId) => routes[memberId];
}
