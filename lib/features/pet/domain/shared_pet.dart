import '../../circle/domain/circle.dart';
import 'pet_care_action.dart';

/// How the companion is doing on the care stats. Distinct from PetMood,
/// which describes what the circle is up to.
enum PetCareMood { happy, content, hungry, sleepy, dirty, playing }

/// The circle's shared companion. Stats are doubles so slow decay is not lost
/// to rounding between render ticks; screens round for display.
class SharedPet {
  const SharedPet({
    required this.name,
    required this.species,
    required this.level,
    required this.experience,
    required this.hunger,
    required this.energy,
    required this.hygiene,
    required this.happiness,
    required this.updatedAt,
    this.lastAction,
    this.lastActionAt,
  });

  static const double maxStat = 100;
  static const int experiencePerLevel = 100;
  static const Duration playingWindow = Duration(minutes: 2);

  /// Builds the live companion state stored alongside the circle. Callers
  /// should apply [decayed] up to the current time before rendering.
  factory SharedPet.fromCircle(Circle circle) {
    return SharedPet(
      name: circle.petName,
      species: circle.petId,
      level: circle.petLevel,
      experience: circle.petExperience,
      hunger: circle.petHunger,
      energy: circle.petEnergy,
      hygiene: circle.petHygiene,
      happiness: circle.petHappiness,
      updatedAt: circle.petUpdatedAt ?? circle.createdAt,
      lastAction: _careAction(circle.petLastAction),
      lastActionAt: circle.petLastActionAt,
    );
  }

  static PetCareAction? _careAction(String? name) {
    for (final action in PetCareAction.values) {
      if (action.name == name) return action;
    }
    return null;
  }

  final String name;
  final String species;
  final int level;
  final int experience;
  final double hunger;
  final double energy;
  final double hygiene;
  final double happiness;
  final DateTime updatedAt;
  final PetCareAction? lastAction;
  final DateTime? lastActionAt;

  int get xpIntoLevel => experience % experiencePerLevel;

  double get levelProgress => xpIntoLevel / experiencePerLevel;

  PetCareMood careMoodAt(DateTime now) {
    final actionAt = lastActionAt;
    if (lastAction == PetCareAction.play &&
        actionAt != null &&
        now.difference(actionAt) < playingWindow) {
      return PetCareMood.playing;
    }
    if (energy < 25) return PetCareMood.sleepy;
    if (hunger < 30) return PetCareMood.hungry;
    if (hygiene < 30) return PetCareMood.dirty;
    if (happiness >= 70) return PetCareMood.happy;
    return PetCareMood.content;
  }

  SharedPet caredFor(PetCareAction action, DateTime at) {
    final totalExperience = experience + action.experience;
    return SharedPet(
      name: name,
      species: species,
      level: 1 + totalExperience ~/ experiencePerLevel,
      experience: totalExperience,
      hunger: _clamp(hunger + action.hunger),
      energy: _clamp(energy + action.energy),
      hygiene: _clamp(hygiene + action.hygiene),
      happiness: _clamp(happiness + action.happiness),
      updatedAt: at,
      lastAction: action,
      lastActionAt: at,
    );
  }

  /// Applies the slow drift that happens while nobody is caring for the pet.
  /// Rates are per hour; [now] becomes the new reference point.
  SharedPet decayed(Duration elapsed, DateTime now) {
    if (elapsed <= Duration.zero) return this;
    final hours = elapsed.inSeconds / 3600;
    return SharedPet(
      name: name,
      species: species,
      level: level,
      experience: experience,
      hunger: _clamp(hunger - hours * 6),
      energy: _clamp(energy - hours * 4),
      hygiene: _clamp(hygiene - hours * 3),
      happiness: _clamp(happiness - hours * 2.5),
      updatedAt: now,
      lastAction: lastAction,
      lastActionAt: lastActionAt,
    );
  }

  static double _clamp(double value) => value.clamp(0, maxStat).toDouble();
}
