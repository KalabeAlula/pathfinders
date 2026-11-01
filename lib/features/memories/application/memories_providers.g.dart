// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memories_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memoriesRepository)
final memoriesRepositoryProvider = MemoriesRepositoryProvider._();

final class MemoriesRepositoryProvider
    extends
        $FunctionalProvider<
          MemoriesRepository,
          MemoriesRepository,
          MemoriesRepository
        >
    with $Provider<MemoriesRepository> {
  MemoriesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoriesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoriesRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemoriesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MemoriesRepository create(Ref ref) {
    return memoriesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoriesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoriesRepository>(value),
    );
  }
}

String _$memoriesRepositoryHash() =>
    r'8912d9e9593a0e7c0d00fe3da8cc409aace344f4';

@ProviderFor(recentMemories)
final recentMemoriesProvider = RecentMemoriesProvider._();

final class RecentMemoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemoryPost>>,
          List<MemoryPost>,
          Stream<List<MemoryPost>>
        >
    with $FutureModifier<List<MemoryPost>>, $StreamProvider<List<MemoryPost>> {
  RecentMemoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentMemoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentMemoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<MemoryPost>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MemoryPost>> create(Ref ref) {
    return recentMemories(ref);
  }
}

String _$recentMemoriesHash() => r'4561ae1342acec8b14fc8cafd3ded011588d26fe';
