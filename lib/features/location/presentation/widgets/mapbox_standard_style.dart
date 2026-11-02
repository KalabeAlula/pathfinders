import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Shared Mapbox Standard configuration.
///
/// Standard is the only style that ships named POIs, landmarks and extruded
/// buildings, so both the dashboard preview and the destination picker use it.
abstract final class MapboxStandardStyle {
  static const uri = MapboxStyles.STANDARD;
  static const importId = 'basemap';

  /// A gentle tilt keeps the preview readable while hinting at the 3D city.
  static const previewPitch = 28.0;

  /// The picker opens tilted enough to read facades and still aim precisely.
  static const pickerPitch = 24.0;

  /// Selecting a venue tilts further so the building reads in perspective.
  static const venuePitch = 45.0;

  /// Turns on 3D objects and every label class a Maps-style search expects.
  /// [dark] switches the lighting preset instead of using a different style.
  ///
  /// Facades are off by default in Standard, so the individual toggles are set
  /// explicitly instead of relying on [show3dObjects] alone.
  static Future<void> apply(MapboxMap map, {required bool dark}) async {
    try {
      await map.setStyleImportConfigProperties(importId, {
        'show3dObjects': true,
        'show3dBuildings': true,
        'show3dFacades': true,
        'show3dLandmarks': true,
        'show3dTrees': true,
        'showPointOfInterestLabels': true,
        'showPlaceLabels': true,
        'showTransitLabels': true,
        'showRoadLabels': true,
        'showLandmarkIcons': true,
        'showLandmarkIconLabels': true,
        'lightPreset': dark ? 'night' : 'day',
      });
    } catch (_) {
      // Thrown only while the Standard import is still streaming in.
    }
  }
}
