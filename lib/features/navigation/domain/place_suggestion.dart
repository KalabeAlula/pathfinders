/// One Mapbox geocoding result, shaped for the map's search list.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    this.category,
    this.maki,
  });

  /// Full `place_name`, kept for callers that only need one line.
  final String label;

  /// The place's own name, e.g. "Blue Nile Cinema".
  final String? name;

  /// The secondary line, e.g. "Bole, Addis Ababa".
  final String? address;

  /// Mapbox `properties.category`, e.g. "cinema" or "cafe".
  final String? category;

  /// Mapbox `properties.maki`, the POI icon key.
  final String? maki;

  final double latitude;
  final double longitude;

  String get displayName {
    final value = name?.trim();
    return value == null || value.isEmpty ? label : value;
  }

  /// A human label such as "Cafe" or "Cinema", or null when Mapbox only
  /// reports the generic "poi" group.
  String? get categoryLabel {
    final raw = category?.trim();
    if (raw == null || raw.isEmpty || raw == 'poi') return null;
    final words = raw.replaceAll(RegExp('[-_]'), ' ').trim();
    if (words.isEmpty) return null;
    return words
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  static PlaceSuggestion? fromFeature(Object? raw) {
    if (raw is! Map) return null;

    final placeName = raw['place_name'];
    if (placeName is! String || placeName.trim().isEmpty) return null;

    final center = raw['center'];
    if (center is! List || center.length < 2) return null;
    final longitude = center[0];
    final latitude = center[1];
    if (longitude is! num || latitude is! num) return null;

    final label = placeName.trim();
    final text = raw['text'];
    final name = text is String && text.trim().isNotEmpty ? text.trim() : label;

    final properties = raw['properties'];
    final props = properties is Map ? properties : const {};

    return PlaceSuggestion(
      label: label,
      name: name,
      address: _addressFrom(label: label, name: name, props: props),
      category: _text(props['category']) ?? _text(props['maki']),
      maki: _text(props['maki']),
      longitude: longitude.toDouble(),
      latitude: latitude.toDouble(),
    );
  }
}

String? _addressFrom({
  required String label,
  required String name,
  required Map props,
}) {
  if (label != name) {
    final prefix = '$name, ';
    final address = label.startsWith(prefix)
        ? label.substring(prefix.length).trim()
        : label;
    if (address.isNotEmpty && address != name) return address;
  }
  return _text(props['address']);
}

String? _text(Object? value) {
  final text = value is String ? value.trim() : null;
  return text == null || text.isEmpty ? null : text;
}
