// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memories_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memoriesRepository)
final memoriesRepositoryProvider = MemoriesRepositoryFamily._();

final class MemoriesRepositoryProvider
    extends
        $FunctionalProvider<
          MemoriesRepository,
          MemoriesRepository,
          MemoriesRepository
        >
    with $Provider<MemoriesRepository> {
  MemoriesRepositoryProvider._({
    required MemoriesRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'memoriesRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memoriesRepositoryHash();

  @override
  String toString() {
    return r'memoriesRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<MemoriesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MemoriesRepository create(Ref ref) {
    final argument = this.argument as String;
    return memoriesRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoriesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoriesRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemoriesRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memoriesRepositoryHash() =>
    r'f264191c577769880cfad4651b05877a9a2c5f2c';

final class MemoriesRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<MemoriesRepository, String> {
  MemoriesRepositoryFamily._()
    : super(
        retry: null,
        name: r'memoriesRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  MemoriesRepositoryProvider call(String circleId) =>
      MemoriesRepositoryProvider._(argument: circleId, from: this);

  @override
  String toString() => r'memoriesRepositoryProvider';
}

@ProviderFor(recentMemories)
final recentMemoriesProvider = RecentMemoriesFamily._();

final class RecentMemoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemoryPost>>,
          List<MemoryPost>,
          Stream<List<MemoryPost>>
        >
    with $FutureModifier<List<MemoryPost>>, $StreamProvider<List<MemoryPost>> {
  RecentMemoriesProvider._({
    required RecentMemoriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recentMemoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentMemoriesHash();

  @override
  String toString() {
    return r'recentMemoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MemoryPost>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MemoryPost>> create(Ref ref) {
    final argument = this.argument as String;
    return recentMemories(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentMemoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentMemoriesHash() => r'c3e1db5070b1b48a7e022e1bff01a5fab3dfdf33';

final class RecentMemoriesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MemoryPost>>, String> {
  RecentMemoriesFamily._()
    : super(
        retry: null,
        name: r'recentMemoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecentMemoriesProvider call(String circleId) =>
      RecentMemoriesProvider._(argument: circleId, from: this);

  @override
  String toString() => r'recentMemoriesProvider';
}
