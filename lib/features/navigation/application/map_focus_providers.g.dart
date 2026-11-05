// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_focus_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lets any tab ask the map tab to look at a place without owning the map.

@ProviderFor(MapFocusController)
final mapFocusControllerProvider = MapFocusControllerProvider._();

/// Lets any tab ask the map tab to look at a place without owning the map.
final class MapFocusControllerProvider
    extends $NotifierProvider<MapFocusController, MapFocusRequest?> {
  /// Lets any tab ask the map tab to look at a place without owning the map.
  MapFocusControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapFocusControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapFocusControllerHash();

  @$internal
  @override
  MapFocusController create() => MapFocusController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapFocusRequest? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapFocusRequest?>(value),
    );
  }
}

String _$mapFocusControllerHash() =>
    r'59d7d1a38efea9f3623db87020ff73dc21e2a82f';

/// Lets any tab ask the map tab to look at a place without owning the map.

abstract class _$MapFocusController extends $Notifier<MapFocusRequest?> {
  MapFocusRequest? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MapFocusRequest?, MapFocusRequest?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapFocusRequest?, MapFocusRequest?>,
              MapFocusRequest?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
