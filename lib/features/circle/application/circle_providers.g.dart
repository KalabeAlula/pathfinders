// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'circle_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(circleRepository)
final circleRepositoryProvider = CircleRepositoryFamily._();

final class CircleRepositoryProvider
    extends
        $FunctionalProvider<
          CircleRepository,
          CircleRepository,
          CircleRepository
        >
    with $Provider<CircleRepository> {
  CircleRepositoryProvider._({
    required CircleRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'circleRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$circleRepositoryHash();

  @override
  String toString() {
    return r'circleRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CircleRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CircleRepository create(Ref ref) {
    final argument = this.argument as String;
    return circleRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CircleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CircleRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CircleRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$circleRepositoryHash() => r'dbc3381f6222e04fb4df9634fb441e2f7c0726aa';

final class CircleRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<CircleRepository, String> {
  CircleRepositoryFamily._()
    : super(
        retry: null,
        name: r'circleRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  CircleRepositoryProvider call(String userId) =>
      CircleRepositoryProvider._(argument: userId, from: this);

  @override
  String toString() => r'circleRepositoryProvider';
}

@ProviderFor(circleSnapshot)
final circleSnapshotProvider = CircleSnapshotFamily._();

final class CircleSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<CircleSnapshot?>,
          CircleSnapshot?,
          Stream<CircleSnapshot?>
        >
    with $FutureModifier<CircleSnapshot?>, $StreamProvider<CircleSnapshot?> {
  CircleSnapshotProvider._({
    required CircleSnapshotFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'circleSnapshotProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$circleSnapshotHash();

  @override
  String toString() {
    return r'circleSnapshotProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<CircleSnapshot?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CircleSnapshot?> create(Ref ref) {
    final argument = this.argument as String;
    return circleSnapshot(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CircleSnapshotProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$circleSnapshotHash() => r'0e5a9eba43dc52cbc180a7585c36d83087e587ee';

final class CircleSnapshotFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CircleSnapshot?>, String> {
  CircleSnapshotFamily._()
    : super(
        retry: null,
        name: r'circleSnapshotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CircleSnapshotProvider call(String userId) =>
      CircleSnapshotProvider._(argument: userId, from: this);

  @override
  String toString() => r'circleSnapshotProvider';
}
