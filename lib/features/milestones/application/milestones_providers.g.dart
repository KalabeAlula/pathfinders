// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestones_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(milestonesRepository)
final milestonesRepositoryProvider = MilestonesRepositoryFamily._();

final class MilestonesRepositoryProvider
    extends
        $FunctionalProvider<
          MilestonesRepository,
          MilestonesRepository,
          MilestonesRepository
        >
    with $Provider<MilestonesRepository> {
  MilestonesRepositoryProvider._({
    required MilestonesRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'milestonesRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$milestonesRepositoryHash();

  @override
  String toString() {
    return r'milestonesRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<MilestonesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MilestonesRepository create(Ref ref) {
    final argument = this.argument as String;
    return milestonesRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MilestonesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MilestonesRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MilestonesRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$milestonesRepositoryHash() =>
    r'd2b0b1369f3924b7f2decb67fd1682b20712efef';

final class MilestonesRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<MilestonesRepository, String> {
  MilestonesRepositoryFamily._()
    : super(
        retry: null,
        name: r'milestonesRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  MilestonesRepositoryProvider call(String circleId) =>
      MilestonesRepositoryProvider._(argument: circleId, from: this);

  @override
  String toString() => r'milestonesRepositoryProvider';
}

@ProviderFor(milestones)
final milestonesProvider = MilestonesFamily._();

final class MilestonesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SharedMilestone>>,
          List<SharedMilestone>,
          Stream<List<SharedMilestone>>
        >
    with
        $FutureModifier<List<SharedMilestone>>,
        $StreamProvider<List<SharedMilestone>> {
  MilestonesProvider._({
    required MilestonesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'milestonesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$milestonesHash();

  @override
  String toString() {
    return r'milestonesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SharedMilestone>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SharedMilestone>> create(Ref ref) {
    final argument = this.argument as String;
    return milestones(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MilestonesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$milestonesHash() => r'1e6722001bbc58a106ac442c4397a2595b55da52';

final class MilestonesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SharedMilestone>>, String> {
  MilestonesFamily._()
    : super(
        retry: null,
        name: r'milestonesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MilestonesProvider call(String circleId) =>
      MilestonesProvider._(argument: circleId, from: this);

  @override
  String toString() => r'milestonesProvider';
}
