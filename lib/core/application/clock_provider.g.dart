// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ticks so relative copy ("4m ago", dwell time) stays honest on a screen that
/// otherwise only rebuilds when data changes.

@ProviderFor(appClock)
final appClockProvider = AppClockProvider._();

/// Ticks so relative copy ("4m ago", dwell time) stays honest on a screen that
/// otherwise only rebuilds when data changes.

final class AppClockProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// Ticks so relative copy ("4m ago", dwell time) stays honest on a screen that
  /// otherwise only rebuilds when data changes.
  AppClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appClockHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return appClock(ref);
  }
}

String _$appClockHash() => r'248d7480c8d4f8da68d581c4c99cf75e0d586cc4';
