// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(petRepository)
final petRepositoryProvider = PetRepositoryProvider._();

final class PetRepositoryProvider
    extends $FunctionalProvider<PetRepository, PetRepository, PetRepository>
    with $Provider<PetRepository> {
  PetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'petRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$petRepositoryHash();

  @$internal
  @override
  $ProviderElement<PetRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PetRepository create(Ref ref) {
    return petRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PetRepository>(value),
    );
  }
}

String _$petRepositoryHash() => r'a58475c8e18730ad91492749b5de6ca4da40fe2f';

@ProviderFor(PetController)
final petControllerProvider = PetControllerProvider._();

final class PetControllerProvider
    extends $StreamNotifierProvider<PetController, SharedPet> {
  PetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'petControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$petControllerHash();

  @$internal
  @override
  PetController create() => PetController();
}

String _$petControllerHash() => r'9380b7e9661b9beb99625b8f1eee249a1bcdebe3';

abstract class _$PetController extends $StreamNotifier<SharedPet> {
  Stream<SharedPet> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SharedPet>, SharedPet>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SharedPet>, SharedPet>,
              AsyncValue<SharedPet>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
