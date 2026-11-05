import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../location/domain/geo_point.dart';

part 'map_focus_providers.g.dart';

/// A map camera request raised outside the map tab, e.g. from a chat bubble.
class MapFocusRequest {
  const MapFocusRequest({
    required this.point,
    required this.revision,
    this.label,
  });

  final GeoPoint point;
  final String? label;

  /// Distinguishes two requests for the same coordinate.
  final int revision;
}

/// Lets any tab ask the map tab to look at a place without owning the map.
@Riverpod(keepAlive: true)
class MapFocusController extends _$MapFocusController {
  int _revision = 0;

  @override
  MapFocusRequest? build() => null;

  void focus(GeoPoint point, {String? label}) {
    state = MapFocusRequest(
      point: point,
      label: label,
      revision: ++_revision,
    );
  }
}
