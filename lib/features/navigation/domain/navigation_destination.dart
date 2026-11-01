import '../../location/domain/geo_point.dart';

/// The one place the whole circle is heading to.
class NavigationDestination {
  const NavigationDestination({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.setBy,
    required this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final String label;
  final String setBy;
  final DateTime updatedAt;

  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);
}
