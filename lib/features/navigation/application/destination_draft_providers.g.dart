// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination_draft_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DestinationDraftController)
final destinationDraftControllerProvider = DestinationDraftControllerFamily._();

final class DestinationDraftControllerProvider
    extends $NotifierProvider<DestinationDraftController, DestinationDraft> {
  DestinationDraftControllerProvider._({
    required DestinationDraftControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'destinationDraftControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$destinationDraftControllerHash();

  @override
  String toString() {
    return r'destinationDraftControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DestinationDraftController create() => DestinationDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DestinationDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DestinationDraft>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DestinationDraftControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$destinationDraftControllerHash() =>
    r'790e01c3d157eab33f392bdcc1c9617960fe439f';

final class DestinationDraftControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DestinationDraftController,
          DestinationDraft,
          DestinationDraft,
          DestinationDraft,
          String
        > {
  DestinationDraftControllerFamily._()
    : super(
        retry: null,
        name: r'destinationDraftControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DestinationDraftControllerProvider call(String circleId) =>
      DestinationDraftControllerProvider._(argument: circleId, from: this);

  @override
  String toString() => r'destinationDraftControllerProvider';
}

abstract class _$DestinationDraftController
    extends $Notifier<DestinationDraft> {
  late final _$args = ref.$arg as String;
  String get circleId => _$args;

  DestinationDraft build(String circleId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DestinationDraft, DestinationDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DestinationDraft, DestinationDraft>,
              DestinationDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
