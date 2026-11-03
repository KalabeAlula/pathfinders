/// Companions native to Ethiopia, grouped by the social shape they mirror.
///
/// [id] values are persisted in `circles.pet_id`, and the database enforces the
/// same group-type mapping, so changing an id is a migration.
enum EthiopianPet {
  lovebird(
    id: 'lovebird',
    commonName: 'Black-winged Lovebird',
    scientificName: 'Agapornis taranta',
    amharicName: 'ፍቅር ወፍ',
    habitat: 'Ethiopian highlands',
    funFact: 'Pairs bond for life and preen each other every day.',
    avatarAsset: 'assets/pets/lovebird.png',
    defaultName: 'Fikir',
    emoji: '🦜',
  ),
  ethiopianWolf(
    id: 'ethiopian_wolf',
    commonName: 'Ethiopian Wolf',
    scientificName: 'Canis simensis',
    amharicName: 'ቀይ ቀበሮ',
    habitat: 'Bale and Simien Mountains',
    funFact: 'Africa’s rarest canid hunts alone but dens with a loyal mate.',
    avatarAsset: 'assets/pets/ethiopian_wolf.png',
    defaultName: 'Sene',
    emoji: '🐺',
  ),
  gelada(
    id: 'gelada',
    commonName: 'Gelada',
    scientificName: 'Theropithecus gelada',
    amharicName: 'ጨለዳ',
    habitat: 'Simien Mountains plateau',
    funFact: 'Troops groom and chatter all day to keep friendships strong.',
    avatarAsset: 'assets/pets/gelada.png',
    defaultName: 'Chele',
    emoji: '🐒',
  ),
  baleMonkey(
    id: 'bale_monkey',
    commonName: 'Bale Monkey',
    scientificName: 'Chlorocebus djamdjamensis',
    amharicName: 'የባሌ ዝንጀሮ',
    habitat: 'Bale Mountains bamboo forest',
    funFact: 'Agile troops leap through bamboo and play chase for hours.',
    avatarAsset: 'assets/pets/bale_monkey.png',
    defaultName: 'Bale',
    emoji: '🐵',
  ),
  waliaIbex(
    id: 'walia_ibex',
    commonName: 'Walia Ibex',
    scientificName: 'Capra walie',
    amharicName: 'ዋልያ',
    habitat: 'Simien Mountains cliffs',
    funFact: 'Herds post lookouts on cliff edges to guard the young.',
    avatarAsset: 'assets/pets/walia_ibex.png',
    defaultName: 'Walia',
    emoji: '🐐',
  ),
  ethiopianLion(
    id: 'lion',
    commonName: 'Black-maned Ethiopian Lion',
    scientificName: 'Panthera leo',
    amharicName: 'አንበሳ',
    habitat: 'Bale Mountains and southern savanna',
    funFact: 'A pride raises its cubs together and guards the whole family.',
    avatarAsset: 'assets/pets/lion.png',
    defaultName: 'Anbessa',
    emoji: '🦁',
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

  static const fallback = lovebird;

  static EthiopianPet byId(String? id) => tryById(id) ?? fallback;

  static EthiopianPet? tryById(String? id) {
    for (final pet in values) {
      if (pet.id == id) return pet;
    }
    return null;
  }
}
