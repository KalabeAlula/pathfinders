/// Companions the circle adopts and cares for together.
///
/// [id] values are persisted in `circles.pet_id` and validated by the
/// database, so changing an id requires a migration.
enum EthiopianPet {
  fox(
    id: 'fox',
    commonName: 'Fox',
    scientificName: 'Vulpes vulpes',
    amharicName: 'ቀበሮ',
    habitat: 'Highland ridges',
    funFact: 'Clever, quick-footed, and always first to spot a shortcut.',
    avatarAsset: 'assets/pets/fox.png',
    defaultName: 'Foxy',
    emoji: '🦊',
  ),
  seagull(
    id: 'seagull',
    commonName: 'Seagull',
    scientificName: 'Larus canus',
    amharicName: 'የባሕር ወፍ',
    habitat: 'Open skies and coasts',
    funFact: 'Keeps watch from above and never misses a snack stop.',
    avatarAsset: 'assets/pets/seagull.png',
    defaultName: 'Gulliver',
    emoji: '🕊️',
  ),
  dog(
    id: 'dog',
    commonName: 'Dachshund',
    scientificName: 'Canis familiaris',
    amharicName: 'ውሻ',
    habitat: 'Every cozy home',
    funFact: 'Small legs, boundless loyalty, and always ready for a walk.',
    avatarAsset: 'assets/pets/dog.png',
    defaultName: 'Salchicha',
    emoji: '🐶',
  ),
  orangutan(
    id: 'orangutan',
    commonName: 'Orangutan',
    scientificName: 'Pongo pygmaeus',
    amharicName: 'ኦራንጉታን',
    habitat: 'Canopy treetops',
    funFact: 'Builds a fresh leafy nest every night and loves unhurried company.',
    avatarAsset: 'assets/pets/orangutan.png',
    defaultName: 'Bobo',
    emoji: '🦧',
  );

  const EthiopianPet({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.amharicName,
    required this.habitat,
    required this.funFact,
    required this.avatarAsset,
    required this.defaultName,
    required this.emoji,
  });

  final String id;
  final String commonName;
  final String scientificName;
  final String amharicName;
  final String habitat;
  final String funFact;
  final String avatarAsset;
  final String defaultName;

  /// Fallback used when the badge asset cannot be decoded.
  final String emoji;

  static const fallback = fox;

  static EthiopianPet byId(String? id) => tryById(id) ?? fallback;

  static EthiopianPet? tryById(String? id) {
    for (final pet in values) {
      if (pet.id == id) return pet;
    }
    return switch (id) {
      'lovebird' || 'lion' => fox,
      'ethiopian_wolf' => seagull,
      'bale_monkey' || 'walia_ibex' => dog,
      'gelada' => orangutan,
      _ => null,
    };
  }
}
