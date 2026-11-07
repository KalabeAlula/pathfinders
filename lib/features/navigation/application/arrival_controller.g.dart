// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arrival_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Detects the local member's arrival at the shared destination, announces it
/// in the crew thread once per trip, and ends the trip once everyone is there.

@ProviderFor(ArrivalController)
final arrivalControllerProvider = ArrivalControllerFamily._();

/// Detects the local member's arrival at the shared destination, announces it
/// in the crew thread once per trip, and ends the trip once everyone is there.
final class ArrivalControllerProvider
    extends $NotifierProvider<ArrivalController, ArrivalState> {
  /// Detects the local member's arrival at the shared destination, announces it
  /// in the crew thread once per trip, and ends the trip once everyone is there.
  ArrivalControllerProvider._({
    required ArrivalControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'arrivalControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$arrivalControllerHash();

  @override
  String toString() {
    return r'arrivalControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ArrivalController create() => ArrivalController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArrivalState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArrivalState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ArrivalControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$arrivalControllerHash() => r'dc5c7a8063e07f7c8d3ec0c057770aab17adf818';

/// Detects the local member's arrival at the shared destination, announces it
/// in the crew thread once per trip, and ends the trip once everyone is there.

final class ArrivalControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ArrivalController,
          ArrivalState,
          ArrivalState,
          ArrivalState,
          String
        > {
  ArrivalControllerFamily._()
    : super(
        retry: null,
        name: r'arrivalControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Detects the local member's arrival at the shared destination, announces it
  /// in the crew thread once per trip, and ends the trip once everyone is there.

  ArrivalControllerProvider call(String circleId) =>
      ArrivalControllerProvider._(argument: circleId, from: this);

  @override
  String toString() => r'arrivalControllerProvider';
}

/// Detects the local member's arrival at the shared destination, announces it
/// in the crew thread once per trip, and ends the trip once everyone is there.

abstract class _$ArrivalController extends $Notifier<ArrivalState> {
  late final _$args = ref.$arg as String;
  String get circleId => _$args;

  ArrivalState build(String circleId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ArrivalState, ArrivalState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ArrivalState, ArrivalState>,
              ArrivalState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
