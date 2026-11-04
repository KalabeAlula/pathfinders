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

@ProviderFor(activeCircleStore)
final activeCircleStoreProvider = ActiveCircleStoreProvider._();

final class ActiveCircleStoreProvider
    extends
        $FunctionalProvider<
          ActiveCircleStore,
          ActiveCircleStore,
          ActiveCircleStore
        >
    with $Provider<ActiveCircleStore> {
  ActiveCircleStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCircleStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCircleStoreHash();

  @$internal
  @override
  $ProviderElement<ActiveCircleStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActiveCircleStore create(Ref ref) {
    return activeCircleStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveCircleStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveCircleStore>(value),
    );
  }
}

String _$activeCircleStoreHash() => r'b06108931780798d00a268b48d10918025309039';

/// Every group the signed-in member belongs to, oldest membership first.

@ProviderFor(circles)
final circlesProvider = CirclesFamily._();

/// Every group the signed-in member belongs to, oldest membership first.

final class CirclesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CircleSummary>>,
          List<CircleSummary>,
          Stream<List<CircleSummary>>
        >
    with
        $FutureModifier<List<CircleSummary>>,
        $StreamProvider<List<CircleSummary>> {
  /// Every group the signed-in member belongs to, oldest membership first.
  CirclesProvider._({
    required CirclesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'circlesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$circlesHash();

  @override
  String toString() {
    return r'circlesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CircleSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CircleSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return circles(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CirclesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$circlesHash() => r'9ce55cc4c143baf97ed68d60a7226ba881169a49';

/// Every group the signed-in member belongs to, oldest membership first.

final class CirclesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<CircleSummary>>, String> {
  CirclesFamily._()
    : super(
        retry: null,
        name: r'circlesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every group the signed-in member belongs to, oldest membership first.

  CirclesProvider call(String userId) =>
      CirclesProvider._(argument: userId, from: this);

  @override
  String toString() => r'circlesProvider';
}

/// The circle whose membership this device just lost, so the gate can explain
/// why the screen changed. Cleared as soon as it is shown.

@ProviderFor(CircleMembershipNotice)
final circleMembershipNoticeProvider = CircleMembershipNoticeProvider._();

/// The circle whose membership this device just lost, so the gate can explain
/// why the screen changed. Cleared as soon as it is shown.
final class CircleMembershipNoticeProvider
    extends $NotifierProvider<CircleMembershipNotice, String?> {
  /// The circle whose membership this device just lost, so the gate can explain
  /// why the screen changed. Cleared as soon as it is shown.
  CircleMembershipNoticeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'circleMembershipNoticeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$circleMembershipNoticeHash();

  @$internal
  @override
  CircleMembershipNotice create() => CircleMembershipNotice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$circleMembershipNoticeHash() =>
    r'88e965d74c2a810e93889483e6796afbf6ba361a';

/// The circle whose membership this device just lost, so the gate can explain
/// why the screen changed. Cleared as soon as it is shown.

abstract class _$CircleMembershipNotice extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The group currently on screen. A saved id wins only while it still matches
/// a membership; otherwise the oldest group is used so a removed group cannot
/// leave the app pointing at nothing.

@ProviderFor(ActiveCircleController)
final activeCircleControllerProvider = ActiveCircleControllerFamily._();

/// The group currently on screen. A saved id wins only while it still matches
/// a membership; otherwise the oldest group is used so a removed group cannot
/// leave the app pointing at nothing.
final class ActiveCircleControllerProvider
    extends $NotifierProvider<ActiveCircleController, String?> {
  /// The group currently on screen. A saved id wins only while it still matches
  /// a membership; otherwise the oldest group is used so a removed group cannot
  /// leave the app pointing at nothing.
  ActiveCircleControllerProvider._({
    required ActiveCircleControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeCircleControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeCircleControllerHash();

  @override
  String toString() {
    return r'activeCircleControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActiveCircleController create() => ActiveCircleController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveCircleControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeCircleControllerHash() =>
    r'69e64c626f9278e4656faa4ba6e3e69976bbe352';

/// The group currently on screen. A saved id wins only while it still matches
/// a membership; otherwise the oldest group is used so a removed group cannot
/// leave the app pointing at nothing.

final class ActiveCircleControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ActiveCircleController,
          String?,
          String?,
          String?,
          String
        > {
  ActiveCircleControllerFamily._()
    : super(
        retry: null,
        name: r'activeCircleControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The group currently on screen. A saved id wins only while it still matches
  /// a membership; otherwise the oldest group is used so a removed group cannot
  /// leave the app pointing at nothing.

  ActiveCircleControllerProvider call(String userId) =>
      ActiveCircleControllerProvider._(argument: userId, from: this);

  @override
  String toString() => r'activeCircleControllerProvider';
}

/// The group currently on screen. A saved id wins only while it still matches
/// a membership; otherwise the oldest group is used so a removed group cannot
/// leave the app pointing at nothing.

abstract class _$ActiveCircleController extends $Notifier<String?> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  String? build(String userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(activeCircle)
final activeCircleProvider = ActiveCircleFamily._();

final class ActiveCircleProvider
    extends $FunctionalProvider<CircleSummary?, CircleSummary?, CircleSummary?>
    with $Provider<CircleSummary?> {
  ActiveCircleProvider._({
    required ActiveCircleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeCircleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeCircleHash();

  @override
  String toString() {
    return r'activeCircleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CircleSummary?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CircleSummary? create(Ref ref) {
    final argument = this.argument as String;
    return activeCircle(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CircleSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CircleSummary?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveCircleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeCircleHash() => r'db19b6f4a898aaa8b687be9ecb8b7149b200e5e9';

final class ActiveCircleFamily extends $Family
    with $FunctionalFamilyOverride<CircleSummary?, String> {
  ActiveCircleFamily._()
    : super(
        retry: null,
        name: r'activeCircleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveCircleProvider call(String userId) =>
      ActiveCircleProvider._(argument: userId, from: this);

  @override
  String toString() => r'activeCircleProvider';
}

/// Live data for the active group. Changing the active id rebuilds this
/// stream, which cancels the previous repository subscription (and its
/// realtime channel) before the next one starts.

@ProviderFor(circleSnapshot)
final circleSnapshotProvider = CircleSnapshotFamily._();

/// Live data for the active group. Changing the active id rebuilds this
/// stream, which cancels the previous repository subscription (and its
/// realtime channel) before the next one starts.

final class CircleSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<CircleSnapshot?>,
          CircleSnapshot?,
          Stream<CircleSnapshot?>
        >
    with $FutureModifier<CircleSnapshot?>, $StreamProvider<CircleSnapshot?> {
  /// Live data for the active group. Changing the active id rebuilds this
  /// stream, which cancels the previous repository subscription (and its
  /// realtime channel) before the next one starts.
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

String _$circleSnapshotHash() => r'df0d0cc8bb785cbe985e5e02c35117fcd9bb0a1b';

/// Live data for the active group. Changing the active id rebuilds this
/// stream, which cancels the previous repository subscription (and its
/// realtime channel) before the next one starts.

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

  /// Live data for the active group. Changing the active id rebuilds this
  /// stream, which cancels the previous repository subscription (and its
  /// realtime channel) before the next one starts.

  CircleSnapshotProvider call(String userId) =>
      CircleSnapshotProvider._(argument: userId, from: this);

  @override
  String toString() => r'circleSnapshotProvider';
}
