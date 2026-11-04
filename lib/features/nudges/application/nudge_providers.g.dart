// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nudge_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nudgeRepository)
final nudgeRepositoryProvider = NudgeRepositoryFamily._();

final class NudgeRepositoryProvider
    extends
        $FunctionalProvider<NudgeRepository, NudgeRepository, NudgeRepository>
    with $Provider<NudgeRepository> {
  NudgeRepositoryProvider._({
    required NudgeRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'nudgeRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nudgeRepositoryHash();

  @override
  String toString() {
    return r'nudgeRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<NudgeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NudgeRepository create(Ref ref) {
    final argument = this.argument as String;
    return nudgeRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NudgeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NudgeRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NudgeRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nudgeRepositoryHash() => r'fdf1f1e46b4678e8777bb798e0f1ed2f4f65cc3d';

final class NudgeRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<NudgeRepository, String> {
  NudgeRepositoryFamily._()
    : super(
        retry: null,
        name: r'nudgeRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  NudgeRepositoryProvider call(String circleId) =>
      NudgeRepositoryProvider._(argument: circleId, from: this);

  @override
  String toString() => r'nudgeRepositoryProvider';
}

/// Shows the most recent warmth action, then clears itself so the banner
/// disappears without the caller managing a timer.

@ProviderFor(NudgeController)
final nudgeControllerProvider = NudgeControllerFamily._();

/// Shows the most recent warmth action, then clears itself so the banner
/// disappears without the caller managing a timer.
final class NudgeControllerProvider
    extends $NotifierProvider<NudgeController, NudgePing?> {
  /// Shows the most recent warmth action, then clears itself so the banner
  /// disappears without the caller managing a timer.
  NudgeControllerProvider._({
    required NudgeControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'nudgeControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nudgeControllerHash();

  @override
  String toString() {
    return r'nudgeControllerProvider'
        ''
        '$argument';
  }

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

  @override
  bool operator ==(Object other) {
    return other is NudgeControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nudgeControllerHash() => r'a039bc9cfefcabbdddc2daae3ee4f6557017602e';

/// Shows the most recent warmth action, then clears itself so the banner
/// disappears without the caller managing a timer.

final class NudgeControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          NudgeController,
          NudgePing?,
          NudgePing?,
          NudgePing?,
          (String, String)
        > {
  NudgeControllerFamily._()
    : super(
        retry: null,
        name: r'nudgeControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Shows the most recent warmth action, then clears itself so the banner
  /// disappears without the caller managing a timer.

  NudgeControllerProvider call(String circleId, String userId) =>
      NudgeControllerProvider._(argument: (circleId, userId), from: this);

  @override
  String toString() => r'nudgeControllerProvider';
}

/// Shows the most recent warmth action, then clears itself so the banner
/// disappears without the caller managing a timer.

abstract class _$NudgeController extends $Notifier<NudgePing?> {
  late final _$args = ref.$arg as (String, String);
  String get circleId => _$args.$1;
  String get userId => _$args.$2;

  NudgePing? build(String circleId, String userId);
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
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
