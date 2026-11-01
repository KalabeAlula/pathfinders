import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mock_pet_repository.dart';
import '../domain/pet_care_action.dart';
import '../domain/pet_repository.dart';
import '../domain/shared_pet.dart';

part 'pet_providers.g.dart';

@Riverpod(keepAlive: true)
PetRepository petRepository(Ref ref) {
  final repository = MockPetRepository();
  ref.onDispose(repository.dispose);
  return repository;
}

@Riverpod(keepAlive: true)
class PetController extends _$PetController {
  @override
  Stream<SharedPet> build() => ref.watch(petRepositoryProvider).watchPet();

  Future<void> care(PetCareAction action) async {
    await ref.read(petRepositoryProvider).care(action);
  }
}
