import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/navigation/domain/place_suggestion.dart';

void main() {
  group('PlaceSuggestion.fromFeature', () {
    test('parses a POI with a secondary address and category', () {
      final place = PlaceSuggestion.fromFeature({
        'text': 'Blue Nile Cinema',
        'place_name': 'Blue Nile Cinema, Bole Road, Addis Ababa, Ethiopia',
        'center': [38.75, 9.01],
        'properties': {'category': 'cinema', 'maki': 'cinema'},
      });

      expect(place, isNotNull);
      expect(place!.displayName, 'Blue Nile Cinema');
      expect(place.address, 'Bole Road, Addis Ababa, Ethiopia');
      expect(place.category, 'cinema');
      expect(place.categoryLabel, 'Cinema');
      expect(place.maki, 'cinema');
      expect(place.latitude, 9.01);
      expect(place.longitude, 38.75);
    });

    test('falls back to maki when Mapbox omits the category', () {
      final place = PlaceSuggestion.fromFeature({
        'text': 'Tomoca',
        'place_name': 'Tomoca, Addis Ababa',
        'center': [38.76, 9.02],
        'properties': {'maki': 'cafe'},
      });

      expect(place?.category, 'cafe');
      expect(place?.categoryLabel, 'Cafe');
    });

    test('uses properties.address when place_name adds no suffix', () {
      final place = PlaceSuggestion.fromFeature({
        'text': 'Tomoca',
        'place_name': 'Tomoca',
        'center': [38.76, 9.02],
        'properties': {'address': 'Wavel Street', 'category': 'cafe'},
      });

      expect(place?.address, 'Wavel Street');
    });

    test('hides the generic poi group', () {
      final place = PlaceSuggestion.fromFeature({
        'text': 'Somewhere',
        'place_name': 'Somewhere, Addis Ababa',
        'center': [38.76, 9.02],
        'properties': {'category': 'poi'},
      });

      expect(place?.categoryLabel, isNull);
    });

    test('rejects features without a usable center', () {
      expect(
        PlaceSuggestion.fromFeature({
          'place_name': 'Nowhere',
          'center': [38.76],
        }),
        isNull,
      );
      expect(PlaceSuggestion.fromFeature({'place_name': 'Nowhere'}), isNull);
      expect(PlaceSuggestion.fromFeature('not a feature'), isNull);
    });

    test('falls back to the full name when Mapbox omits text', () {
      final place = PlaceSuggestion.fromFeature({
        'place_name': 'Meskel Square, Addis Ababa',
        'center': [38.75, 9.01],
      });

      expect(place?.displayName, 'Meskel Square, Addis Ababa');
    });
  });
}
