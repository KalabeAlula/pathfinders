// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(httpClient)
final httpClientProvider = HttpClientProvider._();

final class HttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  HttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return httpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$httpClientHash() => r'7ec49beae0f15115de79f9aa98dbd250130e26d8';

@ProviderFor(navigationRepository)
final navigationRepositoryProvider = NavigationRepositoryFamily._();

final class NavigationRepositoryProvider
    extends
        $FunctionalProvider<
          NavigationRepository,
          NavigationRepository,
          NavigationRepository
        >
    with $Provider<NavigationRepository> {
  NavigationRepositoryProvider._({
    required NavigationRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'navigationRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$navigationRepositoryHash();

  @override
  String toString() {
    return r'navigationRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<NavigationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NavigationRepository create(Ref ref) {
    final argument = this.argument as String;
    return navigationRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NavigationRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$navigationRepositoryHash() =>
    r'20b86d4b6dc6db47244233cea1ad2413260ca138';

final class NavigationRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<NavigationRepository, String> {
  NavigationRepositoryFamily._()
    : super(
        retry: null,
        name: r'navigationRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  NavigationRepositoryProvider call(String circleId) =>
      NavigationRepositoryProvider._(argument: circleId, from: this);

  @override
  String toString() => r'navigationRepositoryProvider';
}

@ProviderFor(circleDestination)
final circleDestinationProvider = CircleDestinationFamily._();

final class CircleDestinationProvider
    extends
        $FunctionalProvider<
          AsyncValue<NavigationDestination?>,
          NavigationDestination?,
          Stream<NavigationDestination?>
        >
    with
        $FutureModifier<NavigationDestination?>,
        $StreamProvider<NavigationDestination?> {
  CircleDestinationProvider._({
    required CircleDestinationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'circleDestinationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$circleDestinationHash();

  @override
  String toString() {
    return r'circleDestinationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<NavigationDestination?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<NavigationDestination?> create(Ref ref) {
    final argument = this.argument as String;
    return circleDestination(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CircleDestinationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$circleDestinationHash() => r'a99ea9dfad85e7574064efa47868e08a1b5ec0dd';

final class CircleDestinationFamily extends $Family
    with $FunctionalFamilyOverride<Stream<NavigationDestination?>, String> {
  CircleDestinationFamily._()
    : super(
        retry: null,
        name: r'circleDestinationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CircleDestinationProvider call(String circleId) =>
      CircleDestinationProvider._(argument: circleId, from: this);

  @override
  String toString() => r'circleDestinationProvider';
}

@ProviderFor(navigationGateway)
final navigationGatewayProvider = NavigationGatewayProvider._();

final class NavigationGatewayProvider
    extends
        $FunctionalProvider<
          NavigationGateway,
          NavigationGateway,
          NavigationGateway
        >
    with $Provider<NavigationGateway> {
  NavigationGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationGatewayHash();

  @$internal
  @override
  $ProviderElement<NavigationGateway> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NavigationGateway create(Ref ref) {
    return navigationGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationGateway>(value),
    );
  }
}

String _$navigationGatewayHash() => r'b94bab86da262021436ed09d2e2aae9a64698a4a';

/// Keeps one route per member up to date between the live fixes and the
/// shared destination.

@ProviderFor(NavigationController)
final navigationControllerProvider = NavigationControllerFamily._();

/// Keeps one route per member up to date between the live fixes and the
/// shared destination.
final class NavigationControllerProvider
    extends $NotifierProvider<NavigationController, NavigationState> {
  /// Keeps one route per member up to date between the live fixes and the
  /// shared destination.
  NavigationControllerProvider._({
    required NavigationControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'navigationControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$navigationControllerHash();

  @override
  String toString() {
    return r'navigationControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NavigationController create() => NavigationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NavigationControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$navigationControllerHash() =>
    r'f91730ed003c6db62104796982b831fe593a1866';

/// Keeps one route per member up to date between the live fixes and the
/// shared destination.

final class NavigationControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          NavigationController,
          NavigationState,
          NavigationState,
          NavigationState,
          String
        > {
  NavigationControllerFamily._()
    : super(
        retry: null,
        name: r'navigationControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keeps one route per member up to date between the live fixes and the
  /// shared destination.

  NavigationControllerProvider call(String circleId) =>
      NavigationControllerProvider._(argument: circleId, from: this);

  @override
  String toString() => r'navigationControllerProvider';
}

/// Keeps one route per member up to date between the live fixes and the
/// shared destination.

abstract class _$NavigationController extends $Notifier<NavigationState> {
  late final _$args = ref.$arg as String;
  String get circleId => _$args;

  NavigationState build(String circleId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NavigationState, NavigationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NavigationState, NavigationState>,
              NavigationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
