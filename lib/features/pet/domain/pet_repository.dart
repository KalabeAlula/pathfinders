import 'pet_care_action.dart';
import 'shared_pet.dart';

abstract interface class PetRepository {
  Stream<SharedPet> watchPet();

  Future<SharedPet> care(PetCareAction action);
}
