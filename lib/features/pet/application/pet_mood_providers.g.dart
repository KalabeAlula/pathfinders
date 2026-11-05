// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_mood_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The companion's sticker state for [circleId].
///
/// Both watches are narrowed to the fields the mood needs: distance ticks and
/// member telemetry keep flowing without rebuilding every sticker.

@ProviderFor(petMood)
final petMoodProvider = PetMoodFamily._();

/// The companion's sticker state for [circleId].
///
/// Both watches are narrowed to the fields the mood needs: distance ticks and
/// member telemetry keep flowing without rebuilding every sticker.

final class PetMoodProvider
    extends $FunctionalProvider<PetMood, PetMood, PetMood>
    with $Provider<PetMood> {
  /// The companion's sticker state for [circleId].
  ///
  /// Both watches are narrowed to the fields the mood needs: distance ticks and
  /// member telemetry keep flowing without rebuilding every sticker.
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

String _$petMoodHash() => r'555168e0f2188e7732a985e1bc6ed10b9481cacd';

/// The companion's sticker state for [circleId].
///
/// Both watches are narrowed to the fields the mood needs: distance ticks and
/// member telemetry keep flowing without rebuilding every sticker.

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
  /// Both watches are narrowed to the fields the mood needs: distance ticks and
  /// member telemetry keep flowing without rebuilding every sticker.

  PetMoodProvider call(String circleId) =>
      PetMoodProvider._(argument: circleId, from: this);

  @override
  String toString() => r'petMoodProvider';
}
