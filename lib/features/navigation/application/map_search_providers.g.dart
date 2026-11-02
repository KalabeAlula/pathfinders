// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Debounced Mapbox autocomplete for the map's search bar.
///
/// Results are biased around the member's last GPS fix so nearby cafes and
/// streets rank above far-away matches.

@ProviderFor(MapSearchController)
final mapSearchControllerProvider = MapSearchControllerFamily._();

/// Debounced Mapbox autocomplete for the map's search bar.
///
/// Results are biased around the member's last GPS fix so nearby cafes and
/// streets rank above far-away matches.
final class MapSearchControllerProvider
    extends $NotifierProvider<MapSearchController, MapSearchState> {
  /// Debounced Mapbox autocomplete for the map's search bar.
  ///
  /// Results are biased around the member's last GPS fix so nearby cafes and
  /// streets rank above far-away matches.
  MapSearchControllerProvider._({
    required MapSearchControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mapSearchControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mapSearchControllerHash();

  @override
  String toString() {
    return r'mapSearchControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MapSearchController create() => MapSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapSearchState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MapSearchControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mapSearchControllerHash() =>
    r'3904cd9895490ee6463944c9f192fd39cb286a89';

/// Debounced Mapbox autocomplete for the map's search bar.
///
/// Results are biased around the member's last GPS fix so nearby cafes and
/// streets rank above far-away matches.

final class MapSearchControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MapSearchController,
          MapSearchState,
          MapSearchState,
          MapSearchState,
          String
        > {
  MapSearchControllerFamily._()
    : super(
        retry: null,
        name: r'mapSearchControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Debounced Mapbox autocomplete for the map's search bar.
  ///
  /// Results are biased around the member's last GPS fix so nearby cafes and
  /// streets rank above far-away matches.

  MapSearchControllerProvider call(String userId) =>
      MapSearchControllerProvider._(argument: userId, from: this);

  @override
  String toString() => r'mapSearchControllerProvider';
}

/// Debounced Mapbox autocomplete for the map's search bar.
///
/// Results are biased around the member's last GPS fix so nearby cafes and
/// streets rank above far-away matches.

abstract class _$MapSearchController extends $Notifier<MapSearchState> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  MapSearchState build(String userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MapSearchState, MapSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapSearchState, MapSearchState>,
              MapSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
