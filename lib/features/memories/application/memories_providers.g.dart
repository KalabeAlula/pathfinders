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

@ProviderFor(memoriesSeenStore)
final memoriesSeenStoreProvider = MemoriesSeenStoreProvider._();

final class MemoriesSeenStoreProvider
    extends
        $FunctionalProvider<
          MemoriesSeenStore,
          MemoriesSeenStore,
          MemoriesSeenStore
        >
    with $Provider<MemoriesSeenStore> {
  MemoriesSeenStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoriesSeenStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoriesSeenStoreHash();

  @$internal
  @override
  $ProviderElement<MemoriesSeenStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MemoriesSeenStore create(Ref ref) {
    return memoriesSeenStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoriesSeenStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoriesSeenStore>(value),
    );
  }
}

String _$memoriesSeenStoreHash() => r'6f7a351fb383ee0fbb4393bb12049626c7ced93b';

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

/// The moment this device last opened the circle's memories gallery, restored
/// after restarts so the dock badge only counts moments not yet seen.

@ProviderFor(MemoriesSeenController)
final memoriesSeenControllerProvider = MemoriesSeenControllerFamily._();

/// The moment this device last opened the circle's memories gallery, restored
/// after restarts so the dock badge only counts moments not yet seen.
final class MemoriesSeenControllerProvider
    extends $NotifierProvider<MemoriesSeenController, DateTime> {
  /// The moment this device last opened the circle's memories gallery, restored
  /// after restarts so the dock badge only counts moments not yet seen.
  MemoriesSeenControllerProvider._({
    required MemoriesSeenControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'memoriesSeenControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memoriesSeenControllerHash();

  @override
  String toString() {
    return r'memoriesSeenControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MemoriesSeenController create() => MemoriesSeenController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemoriesSeenControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memoriesSeenControllerHash() =>
    r'dc42256a6a65b1328e5ecb2cfb345b9f56f89007';

/// The moment this device last opened the circle's memories gallery, restored
/// after restarts so the dock badge only counts moments not yet seen.

final class MemoriesSeenControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MemoriesSeenController,
          DateTime,
          DateTime,
          DateTime,
          String
        > {
  MemoriesSeenControllerFamily._()
    : super(
        retry: null,
        name: r'memoriesSeenControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The moment this device last opened the circle's memories gallery, restored
  /// after restarts so the dock badge only counts moments not yet seen.

  MemoriesSeenControllerProvider call(String circleId) =>
      MemoriesSeenControllerProvider._(argument: circleId, from: this);

  @override
  String toString() => r'memoriesSeenControllerProvider';
}

/// The moment this device last opened the circle's memories gallery, restored
/// after restarts so the dock badge only counts moments not yet seen.

abstract class _$MemoriesSeenController extends $Notifier<DateTime> {
  late final _$args = ref.$arg as String;
  String get circleId => _$args;

  DateTime build(String circleId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(memoriesUnreadCount)
final memoriesUnreadCountProvider = MemoriesUnreadCountFamily._();

final class MemoriesUnreadCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  MemoriesUnreadCountProvider._({
    required MemoriesUnreadCountFamily super.from,
    required MemoriesUnreadQuery super.argument,
  }) : super(
         retry: null,
         name: r'memoriesUnreadCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memoriesUnreadCountHash();

  @override
  String toString() {
    return r'memoriesUnreadCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as MemoriesUnreadQuery;
    return memoriesUnreadCount(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemoriesUnreadCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memoriesUnreadCountHash() =>
    r'17481a245aa8f222c34dc2b91f3e295deb6d7721';

final class MemoriesUnreadCountFamily extends $Family
    with $FunctionalFamilyOverride<int, MemoriesUnreadQuery> {
  MemoriesUnreadCountFamily._()
    : super(
        retry: null,
        name: r'memoriesUnreadCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemoriesUnreadCountProvider call(MemoriesUnreadQuery query) =>
      MemoriesUnreadCountProvider._(argument: query, from: this);

  @override
  String toString() => r'memoriesUnreadCountProvider';
}
