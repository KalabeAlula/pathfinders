// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(telemetryRepository)
final telemetryRepositoryProvider = TelemetryRepositoryFamily._();

final class TelemetryRepositoryProvider
    extends
        $FunctionalProvider<
          TelemetryRepository,
          TelemetryRepository,
          TelemetryRepository
        >
    with $Provider<TelemetryRepository> {
  TelemetryRepositoryProvider._({
    required TelemetryRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'telemetryRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$telemetryRepositoryHash();

  @override
  String toString() {
    return r'telemetryRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TelemetryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TelemetryRepository create(Ref ref) {
    final argument = this.argument as String;
    return telemetryRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TelemetryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TelemetryRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TelemetryRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$telemetryRepositoryHash() =>
    r'e68a765355e3427a00aceca0c0d13823e2701105';

final class TelemetryRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<TelemetryRepository, String> {
  TelemetryRepositoryFamily._()
    : super(
        retry: null,
        name: r'telemetryRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  TelemetryRepositoryProvider call(String userId) =>
      TelemetryRepositoryProvider._(argument: userId, from: this);

  @override
  String toString() => r'telemetryRepositoryProvider';
}

@ProviderFor(deviceTelemetrySource)
final deviceTelemetrySourceProvider = DeviceTelemetrySourceProvider._();

final class DeviceTelemetrySourceProvider
    extends
        $FunctionalProvider<
          DeviceTelemetrySource,
          DeviceTelemetrySource,
          DeviceTelemetrySource
        >
    with $Provider<DeviceTelemetrySource> {
  DeviceTelemetrySourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceTelemetrySourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceTelemetrySourceHash();

  @$internal
  @override
  $ProviderElement<DeviceTelemetrySource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceTelemetrySource create(Ref ref) {
    return deviceTelemetrySource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceTelemetrySource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceTelemetrySource>(value),
    );
  }
}

String _$deviceTelemetrySourceHash() =>
    r'0a3d298064c4ea7d0e6454847e6d45b122ef93cf';

/// Drives this device's half of the circle telemetry: permission, a fix stream
/// that keeps running off-screen, battery, and the member's sharing mode.

@ProviderFor(TelemetryController)
final telemetryControllerProvider = TelemetryControllerFamily._();

/// Drives this device's half of the circle telemetry: permission, a fix stream
/// that keeps running off-screen, battery, and the member's sharing mode.
final class TelemetryControllerProvider
    extends $NotifierProvider<TelemetryController, TelemetryState> {
  /// Drives this device's half of the circle telemetry: permission, a fix stream
  /// that keeps running off-screen, battery, and the member's sharing mode.
  TelemetryControllerProvider._({
    required TelemetryControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'telemetryControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$telemetryControllerHash();

  @override
  String toString() {
    return r'telemetryControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TelemetryController create() => TelemetryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TelemetryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TelemetryState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TelemetryControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$telemetryControllerHash() =>
    r'792f2c83080f129f426b4ac88ee9be8c1e41b1e9';

/// Drives this device's half of the circle telemetry: permission, a fix stream
/// that keeps running off-screen, battery, and the member's sharing mode.

final class TelemetryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TelemetryController,
          TelemetryState,
          TelemetryState,
          TelemetryState,
          String
        > {
  TelemetryControllerFamily._()
    : super(
        retry: null,
        name: r'telemetryControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives this device's half of the circle telemetry: permission, a fix stream
  /// that keeps running off-screen, battery, and the member's sharing mode.

  TelemetryControllerProvider call(String userId) =>
      TelemetryControllerProvider._(argument: userId, from: this);

  @override
  String toString() => r'telemetryControllerProvider';
}

/// Drives this device's half of the circle telemetry: permission, a fix stream
/// that keeps running off-screen, battery, and the member's sharing mode.

abstract class _$TelemetryController extends $Notifier<TelemetryState> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  TelemetryState build(String userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TelemetryState, TelemetryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TelemetryState, TelemetryState>,
              TelemetryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
