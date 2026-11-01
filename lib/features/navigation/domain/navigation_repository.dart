import 'navigation_destination.dart';

abstract interface class NavigationRepository {
  Stream<NavigationDestination?> watchDestination();

  Future<void> setDestination({
    required String label,
    required double latitude,
    required double longitude,
    required String setBy,
  });

  Future<void> clearDestination();
}
