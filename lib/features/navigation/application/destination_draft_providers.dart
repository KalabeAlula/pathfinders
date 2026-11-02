import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../location/domain/geo_point.dart';
import '../domain/navigation_destination.dart';
import '../domain/navigation_failure.dart';
import 'navigation_providers.dart';

part 'destination_draft_providers.g.dart';

/// The pin a member is positioning on the map, before confirming it as the
/// circle's shared destination.
///
/// A tap can land on a named venue (cafe, cinema, building) or on empty map.
/// Venue drafts keep the venue name and category; a dropped pin resolves its
/// address into [label] instead.
class DestinationDraft {
  const DestinationDraft({
    this.latitude,
    this.longitude,
    this.label,
    this.address,
    this.category,
    this.maki,
    this.isVenue = false,
    this.resolvingAddress = false,
    this.addressUnavailable = false,
  });

  final double? latitude;
  final double? longitude;

  /// The venue name, or the reverse-geocoded label for a dropped pin.
  final String? label;

  /// The street address of a venue, shown under its name.
  final String? address;

  /// Human category, e.g. "Cafe" or "Building".
  final String? category;

  /// Raw Maki id, used to pick the category icon.
  final String? maki;
  final bool isVenue;
  final bool resolvingAddress;
  final bool addressUnavailable;

  bool get hasPoint => latitude != null && longitude != null;

  GeoPoint? get point =>
      hasPoint ? GeoPoint(latitude: latitude!, longitude: longitude!) : null;

  String get coordinates => hasPoint
      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
      : '';

  String get displayLabel {
    final name = label?.trim();
    if (name != null && name.isNotEmpty) return name;
    return hasPoint ? coordinates : 'Tap the map to drop a pin';
  }

  /// The line under the title: a venue's address, or the pin's coordinates.
  String get detail {
    final street = address?.trim();
    if (street != null && street.isNotEmpty) return street;
    return coordinates;
  }

  DestinationDraft copyWith({
    double? latitude,
    double? longitude,
    String? label,
    String? address,
    String? category,
    String? maki,
    bool? isVenue,
    bool? resolvingAddress,
    bool? addressUnavailable,
  }) {
    return DestinationDraft(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      address: address ?? this.address,
      category: category ?? this.category,
      maki: maki ?? this.maki,
      isVenue: isVenue ?? this.isVenue,
      resolvingAddress: resolvingAddress ?? this.resolvingAddress,
      addressUnavailable: addressUnavailable ?? this.addressUnavailable,
    );
  }
}

@riverpod
class DestinationDraftController extends _$DestinationDraftController {
  int _lookup = 0;
  String? _lastPointKey;

  @override
  DestinationDraft build(String circleId) {
    ref.onDispose(() => _lookup++);
    return const DestinationDraft();
  }

  /// Keeps the existing shared destination as the starting pin.
  void seed(NavigationDestination destination) {
    if (state.hasPoint) return;
    _lastPointKey = '${destination.latitude},${destination.longitude}';
    state = DestinationDraft(
      latitude: destination.latitude,
      longitude: destination.longitude,
      label: destination.label,
    );
  }

  /// Drops a plain pin. An empty [label] triggers a reverse geocode lookup; a
  /// non-null one is kept as-is (search results, seed).
  void select(double latitude, double longitude, {String? label}) {
    final key = '$latitude,$longitude';
    if (key == _lastPointKey && label == null && state.label != null) return;

    _lastPointKey = key;
    _lookup++;
    state = DestinationDraft(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
    if (label == null) {
      unawaited(_resolveAddress(latitude, longitude, intoLabel: true));
    }
  }

  /// Selects a named POI or building. The address is looked up separately so
  /// the venue name stays the title.
  void selectVenue({
    required double latitude,
    required double longitude,
    String? name,
    String? address,
    String? category,
    String? maki,
  }) {
    final clean = address?.trim();
    final hasAddress = clean != null && clean.isNotEmpty;

    _lastPointKey = '$latitude,$longitude';
    _lookup++;
    state = DestinationDraft(
      latitude: latitude,
      longitude: longitude,
      label: name,
      address: hasAddress ? clean : null,
      category: category,
      maki: maki,
      isVenue: true,
      resolvingAddress: !hasAddress,
    );
    if (!hasAddress) {
      unawaited(_resolveAddress(latitude, longitude, intoLabel: name == null));
    }
  }

  Future<void> _resolveAddress(
    double latitude,
    double longitude, {
    required bool intoLabel,
  }) async {
    final run = ++_lookup;
    state = state.copyWith(resolvingAddress: true, addressUnavailable: false);

    try {
      final label = await ref
          .read(navigationGatewayProvider)
          .reverseGeocode(GeoPoint(latitude: latitude, longitude: longitude));
      if (!ref.mounted || run != _lookup) return;
      state = state.copyWith(
        label: intoLabel ? label : null,
        address: intoLabel ? null : label,
        resolvingAddress: false,
        addressUnavailable: label == null,
      );
    } on NavigationFailure {
      if (!ref.mounted || run != _lookup) return;
      state = state.copyWith(resolvingAddress: false, addressUnavailable: true);
    }
  }
}
