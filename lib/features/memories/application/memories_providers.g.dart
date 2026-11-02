// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memories_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memoriesCache)
final memoriesCacheProvider = MemoriesCacheFamily._();

final class MemoriesCacheProvider
    extends $FunctionalProvider<MemoriesCache, MemoriesCache, MemoriesCache>
    with $Provider<MemoriesCache> {
  MemoriesCacheProvider._({
    required MemoriesCacheFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'memoriesCacheProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memoriesCacheHash();

  @override
  String toString() {
    return r'memoriesCacheProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<MemoriesCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemoriesCache create(Ref ref) {
    final argument = this.argument as String;
    return memoriesCache(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoriesCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoriesCache>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemoriesCacheProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memoriesCacheHash() => r'0fea203ba783c46a46c6e41c8c2194c3328b50d4';

final class MemoriesCacheFamily extends $Family
    with $FunctionalFamilyOverride<MemoriesCache, String> {
  MemoriesCacheFamily._()
    : super(
        retry: null,
        name: r'memoriesCacheProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemoriesCacheProvider call(String circleId) =>
      MemoriesCacheProvider._(argument: circleId, from: this);

  @override
  String toString() => r'memoriesCacheProvider';
}

@ProviderFor(memoryPhotoUrls)
final memoryPhotoUrlsProvider = MemoryPhotoUrlsProvider._();

final class MemoryPhotoUrlsProvider
    extends
        $FunctionalProvider<MemoryPhotoUrls, MemoryPhotoUrls, MemoryPhotoUrls>
    with $Provider<MemoryPhotoUrls> {
  MemoryPhotoUrlsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoryPhotoUrlsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoryPhotoUrlsHash();

  @$internal
  @override
  $ProviderElement<MemoryPhotoUrls> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemoryPhotoUrls create(Ref ref) {
    return memoryPhotoUrls(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoryPhotoUrls value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoryPhotoUrls>(value),
    );
  }
}

String _$memoryPhotoUrlsHash() => r'3f9f2da1a5a60c4af3e265a6427a6e77ce554bde';

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
    r'3fe46ba117a5a0936a68d541b14a81b51c6fc006';

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
