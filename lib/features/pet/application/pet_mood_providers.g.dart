// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_mood_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fires [true] for [_lovedDuration] after Feed / Clean / Play, then resets.

@ProviderFor(LovedState)
final lovedStateProvider = LovedStateFamily._();

/// Fires [true] for [_lovedDuration] after Feed / Clean / Play, then resets.
final class LovedStateProvider extends $NotifierProvider<LovedState, bool> {
  /// Fires [true] for [_lovedDuration] after Feed / Clean / Play, then resets.
  LovedStateProvider._({
    required LovedStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lovedStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lovedStateHash();

  @override
  String toString() {
    return r'lovedStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LovedState create() => LovedState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LovedStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lovedStateHash() => r'1664899cf6c067d291c4d337d13665a4811226bc';

/// Fires [true] for [_lovedDuration] after Feed / Clean / Play, then resets.

final class LovedStateFamily extends $Family
    with $ClassFamilyOverride<LovedState, bool, bool, bool, String> {
  LovedStateFamily._()
    : super(
        retry: null,
        name: r'lovedStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fires [true] for [_lovedDuration] after Feed / Clean / Play, then resets.

  LovedStateProvider call(String circleId) =>
      LovedStateProvider._(argument: circleId, from: this);

  @override
  String toString() => r'lovedStateProvider';
}

/// Fires [true] for [_lovedDuration] after Feed / Clean / Play, then resets.

abstract class _$LovedState extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get circleId => _$args;

  bool build(String circleId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The companion's sticker state for [circleId].
///
/// Watches are narrowed via `.select` so distance ticks, member telemetry, and
/// unrelated snapshot fields don't rebuild the sticker.

@ProviderFor(petMood)
final petMoodProvider = PetMoodFamily._();

/// The companion's sticker state for [circleId].
///
/// Watches are narrowed via `.select` so distance ticks, member telemetry, and
/// unrelated snapshot fields don't rebuild the sticker.

final class PetMoodProvider
    extends $FunctionalProvider<PetMood, PetMood, PetMood>
    with $Provider<PetMood> {
  /// The companion's sticker state for [circleId].
  ///
  /// Watches are narrowed via `.select` so distance ticks, member telemetry, and
  /// unrelated snapshot fields don't rebuild the sticker.
  PetMoodProvider._({
    required PetMoodFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'petMoodProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$petMoodHash();

  @override
  String toString() {
    return r'petMoodProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PetMood> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PetMood create(Ref ref) {
    final argument = this.argument as String;
    return petMood(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PetMood value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PetMood>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PetMoodProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$petMoodHash() => r'0e9a80754e5979750d51ac8b47ca906ed8aa9ed8';

/// The companion's sticker state for [circleId].
///
/// Watches are narrowed via `.select` so distance ticks, member telemetry, and
/// unrelated snapshot fields don't rebuild the sticker.

final class PetMoodFamily extends $Family
    with $FunctionalFamilyOverride<PetMood, String> {
  PetMoodFamily._()
    : super(
        retry: null,
        name: r'petMoodProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The companion's sticker state for [circleId].
  ///
  /// Watches are narrowed via `.select` so distance ticks, member telemetry, and
  /// unrelated snapshot fields don't rebuild the sticker.

  PetMoodProvider call(String circleId) =>
      PetMoodProvider._(argument: circleId, from: this);

  @override
  String toString() => r'petMoodProvider';
}
