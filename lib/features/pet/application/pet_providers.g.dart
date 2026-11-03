// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(petRepository)
final petRepositoryProvider = PetRepositoryFamily._();

final class PetRepositoryProvider
    extends $FunctionalProvider<PetRepository, PetRepository, PetRepository>
    with $Provider<PetRepository> {
  PetRepositoryProvider._({
    required PetRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'petRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$petRepositoryHash();

  @override
  String toString() {
    return r'petRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PetRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PetRepository create(Ref ref) {
    final argument = this.argument as String;
    return petRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PetRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PetRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$petRepositoryHash() => r'2280057446c772828ad97132d2d5d3f1c73bbdbd';

final class PetRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<PetRepository, String> {
  PetRepositoryFamily._()
    : super(
        retry: null,
        name: r'petRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PetRepositoryProvider call(String circleId) =>
      PetRepositoryProvider._(argument: circleId, from: this);

  @override
  String toString() => r'petRepositoryProvider';
}
