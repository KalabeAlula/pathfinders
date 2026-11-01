import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/pet/domain/pet_care_action.dart';
import 'package:pathfinders/features/pet/domain/shared_pet.dart';

void main() {
  final createdAt = DateTime(2026, 11, 1, 10);
  final pet = SharedPet(
    name: 'Momo',
    species: 'Capybara',
    level: 3,
    experience: 240,
    hunger: 35,
    energy: 80,
    hygiene: 80,
    happiness: 50,
    updatedAt: createdAt,
  );

  group('decay', () {
    test('drains stats at the documented hourly rates', () {
      final decayed = pet.decayed(
        const Duration(hours: 2),
        createdAt.add(const Duration(hours: 2)),
      );

      expect(decayed.hunger, closeTo(23, 0.001));
      expect(decayed.energy, closeTo(72, 0.001));
      expect(decayed.hygiene, closeTo(74, 0.001));
      expect(decayed.happiness, closeTo(45, 0.001));
      expect(decayed.updatedAt, createdAt.add(const Duration(hours: 2)));
    });

    test('never drops below zero', () {
      final decayed = pet.decayed(
        const Duration(days: 30),
        createdAt.add(const Duration(days: 30)),
      );

      expect(decayed.hunger, 0);
      expect(decayed.energy, 0);
      expect(decayed.hygiene, 0);
      expect(decayed.happiness, 0);
    });

    test('ignores negative or zero elapsed time', () {
      final unchanged = pet.decayed(Duration.zero, createdAt);
      expect(unchanged.updatedAt, createdAt);
      expect(unchanged.hunger, pet.hunger);
    });
  });

  group('care', () {
    test('feeding satisfies hunger without losing xp', () {
      final fed = pet.caredFor(PetCareAction.feed, createdAt);

      expect(fed.hunger, closeTo(69, 0.001));
      expect(fed.experience, 248);
      expect(fed.lastAction, PetCareAction.feed);
      expect(fed.lastActionAt, createdAt);
    });

    test('levels up when experience crosses the threshold', () {
      final nearLevelUp = SharedPet(
        name: 'Momo',
        species: 'Capybara',
        level: 3,
        experience: 295,
        hunger: 60,
        energy: 60,
        hygiene: 60,
        happiness: 60,
        updatedAt: createdAt,
      );

      final played = nearLevelUp.caredFor(PetCareAction.play, createdAt);

      expect(played.experience, 305);
      expect(played.level, 4);
      expect(played.xpIntoLevel, 5);
    });
  });

  group('mood', () {
    test('playing wins briefly after play, then happiness takes over', () {
      final played = SharedPet(
        name: 'Momo',
        species: 'Capybara',
        level: 3,
        experience: 240,
        hunger: 60,
        energy: 60,
        hygiene: 60,
        happiness: 70,
        updatedAt: createdAt,
        lastAction: PetCareAction.play,
        lastActionAt: createdAt,
      );

      expect(played.moodAt(createdAt), PetMood.playing);
      expect(
        played.moodAt(createdAt.add(const Duration(minutes: 5))),
        PetMood.happy,
      );
    });

    test('critical needs take priority', () {
      final hungry = SharedPet(
        name: 'Momo',
        species: 'Capybara',
        level: 1,
        experience: 0,
        hunger: 20,
        energy: 80,
        hygiene: 80,
        happiness: 90,
        updatedAt: createdAt,
      );
      expect(hungry.moodAt(createdAt), PetMood.hungry);

      final sleepy = SharedPet(
        name: 'Momo',
        species: 'Capybara',
        level: 1,
        experience: 0,
        hunger: 80,
        energy: 10,
        hygiene: 80,
        happiness: 80,
        updatedAt: createdAt,
      );
      expect(sleepy.moodAt(createdAt), PetMood.sleepy);
    });
  });
}
