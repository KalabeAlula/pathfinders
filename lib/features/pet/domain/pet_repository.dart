import 'pet_care_action.dart';
import 'shared_pet.dart';

abstract interface class PetRepository {
  Future<SharedPet> care(PetCareAction action);
}
