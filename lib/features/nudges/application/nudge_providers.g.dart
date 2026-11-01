// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nudge_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nudgeRepository)
final nudgeRepositoryProvider = NudgeRepositoryProvider._();

final class NudgeRepositoryProvider
    extends
        $FunctionalProvider<NudgeRepository, NudgeRepository, NudgeRepository>
    with $Provider<NudgeRepository> {
  NudgeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nudgeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nudgeRepositoryHash();

  @$internal
  @override
  $ProviderElement<NudgeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NudgeRepository create(Ref ref) {
    return nudgeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NudgeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NudgeRepository>(value),
    );
  }
}

String _$nudgeRepositoryHash() => r'1dd0de5dc557b3ee8609342fb30c67c2d9de37db';

/// Holds the nudge currently playing on screen. The overlay clears itself so
/// callers only have to send.

@ProviderFor(NudgeController)
final nudgeControllerProvider = NudgeControllerProvider._();

/// Holds the nudge currently playing on screen. The overlay clears itself so
/// callers only have to send.
final class NudgeControllerProvider
    extends $NotifierProvider<NudgeController, NudgePing?> {
  /// Holds the nudge currently playing on screen. The overlay clears itself so
  /// callers only have to send.
  NudgeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nudgeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nudgeControllerHash();

  @$internal
  @override
  NudgeController create() => NudgeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NudgePing? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NudgePing?>(value),
    );
  }
}

String _$nudgeControllerHash() => r'49b6dffd5ee94d3ec02084df47eaa1e25c27e506';

/// Holds the nudge currently playing on screen. The overlay clears itself so
/// callers only have to send.

abstract class _$NudgeController extends $Notifier<NudgePing?> {
  NudgePing? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NudgePing?, NudgePing?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NudgePing?, NudgePing?>,
              NudgePing?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
