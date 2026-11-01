// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestones_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(milestonesRepository)
final milestonesRepositoryProvider = MilestonesRepositoryProvider._();

final class MilestonesRepositoryProvider
    extends
        $FunctionalProvider<
          MilestonesRepository,
          MilestonesRepository,
          MilestonesRepository
        >
    with $Provider<MilestonesRepository> {
  MilestonesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'milestonesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$milestonesRepositoryHash();

  @$internal
  @override
  $ProviderElement<MilestonesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MilestonesRepository create(Ref ref) {
    return milestonesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MilestonesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MilestonesRepository>(value),
    );
  }
}

String _$milestonesRepositoryHash() =>
    r'4452a30921f37a56df3514dd94b9d5c0ce32f790';

@ProviderFor(nextMilestone)
final nextMilestoneProvider = NextMilestoneProvider._();

final class NextMilestoneProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedMilestone?>,
          SharedMilestone?,
          Stream<SharedMilestone?>
        >
    with $FutureModifier<SharedMilestone?>, $StreamProvider<SharedMilestone?> {
  NextMilestoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextMilestoneProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextMilestoneHash();

  @$internal
  @override
  $StreamProviderElement<SharedMilestone?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SharedMilestone?> create(Ref ref) {
    return nextMilestone(ref);
  }
}

String _$nextMilestoneHash() => r'2504db4ff98c70a85e8126419ae11fc3e18da7f7';
