import 'dart:async';

import '../domain/pet_care_action.dart';
import '../domain/pet_repository.dart';
import '../domain/shared_pet.dart';

class MockPetRepository implements PetRepository {
  MockPetRepository() {
    final now = DateTime.now();
    _pet = SharedPet(
      name: 'Momo',
      species: 'Capybara',
      level: 3,
      experience: 240,
      hunger: 62,
      energy: 74,
      hygiene: 81,
      happiness: 76,
      updatedAt: now.subtract(const Duration(minutes: 25)),
      lastAction: PetCareAction.feed,
      lastActionAt: now.subtract(const Duration(hours: 3)),
    );
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _decay(),
    );
  }

  final StreamController<SharedPet> _controller =
      StreamController<SharedPet>.broadcast();
  late final Timer _timer;
  late SharedPet _pet;

  @override
  Stream<SharedPet> watchPet() async* {
    yield _pet;
    yield* _controller.stream;
  }

  @override
  Future<SharedPet> care(PetCareAction action) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final now = DateTime.now();
    _pet = _pet
        .decayed(now.difference(_pet.updatedAt), now)
        .caredFor(action, now);
    _emit();
    return _pet;
  }

  void dispose() {
    _timer.cancel();
    _controller.close();
  }

  void _decay() {
    final now = DateTime.now();
    _pet = _pet.decayed(now.difference(_pet.updatedAt), now);
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_pet);
  }
}
