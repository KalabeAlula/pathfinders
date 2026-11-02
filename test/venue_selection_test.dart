import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/navigation/presentation/venue_selection.dart';

void main() {
  group('venue labels', () {
    test('title-cases the raw POI class', () {
      const venue = VenueHit(
        point: GeoPoint(latitude: 9, longitude: 38.7),
        category: 'fast_food',
      );
      expect(venue.categoryLabel, 'Fast Food');
    });

    test('names an unnamed footprint a building', () {
      const venue = VenueHit(
        point: GeoPoint(latitude: 9, longitude: 38.7),
        category: 'building',
        isBuilding: true,
      );
      expect(venue.categoryLabel, 'Building');
    });

    test('has no category when Standard omits one', () {
      const venue = VenueHit(
        point: GeoPoint(latitude: 9, longitude: 38.7),
        name: 'Tomoca',
      );
      expect(venue.categoryLabel, isNull);
    });

    test('hides the generic poi group', () {
      const venue = VenueHit(
        point: GeoPoint(latitude: 9, longitude: 38.7),
        name: 'Tomoca',
        category: 'poi',
      );
      expect(venue.categoryLabel, isNull);
    });
  });

  group('venue icons', () {
    test('maps common venue categories', () {
      expect(venueIcon(category: 'Cafe'), Icons.local_cafe_rounded);
      expect(venueIcon(category: 'Cinema'), Icons.theater_comedy_rounded);
      expect(venueIcon(category: 'Building'), Icons.apartment_rounded);
      expect(venueIcon(maki: 'restaurant'), Icons.restaurant_rounded);
      expect(venueIcon(maki: 'fuel'), Icons.local_gas_station_rounded);
    });

    test('falls back to a pin for unknown categories', () {
      expect(venueIcon(category: 'quarry'), Icons.place_rounded);
      expect(venueIcon(), Icons.place_rounded);
    });
  });
}
