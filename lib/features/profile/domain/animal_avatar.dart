/// The curated animal portraits a member can wear across the app.
///
/// Ids are stored in `profiles.avatar_id`, so they must stay stable even if an
/// asset is redrawn. [byId] always answers with a usable avatar so a stale or
/// missing id never leaves a pin or header blank.
class AnimalAvatar {
  const AnimalAvatar({
    required this.id,
    required this.name,
    required this.assetPath,
  });

  final String id;
  final String name;
  final String assetPath;

  static const String fallbackId = 'avatar_wolf';

  static const AnimalAvatar wolf = AnimalAvatar(
    id: 'avatar_wolf',
    name: 'Simien Wolf',
    assetPath: 'assets/avatars/wolf.png',
  );
  static const AnimalAvatar lion = AnimalAvatar(
    id: 'avatar_lion',
    name: 'Golden Lion',
    assetPath: 'assets/avatars/lion.png',
  );
  static const AnimalAvatar lovebird = AnimalAvatar(
    id: 'avatar_lovebird',
    name: 'Lovebird',
    assetPath: 'assets/avatars/lovebird.png',
  );
  static const AnimalAvatar ibex = AnimalAvatar(
    id: 'avatar_ibex',
    name: 'Walia Ibex',
    assetPath: 'assets/avatars/ibex.png',
  );
  static const AnimalAvatar gelada = AnimalAvatar(
    id: 'avatar_gelada',
    name: 'Gelada',
    assetPath: 'assets/avatars/gelada.png',
  );
  static const AnimalAvatar monkey = AnimalAvatar(
    id: 'avatar_monkey',
    name: 'Bale Monkey',
    assetPath: 'assets/avatars/monkey.png',
  );
  static const AnimalAvatar owl = AnimalAvatar(
    id: 'avatar_owl',
    name: 'Bubo Owl',
    assetPath: 'assets/avatars/owl.png',
  );
  static const AnimalAvatar bear = AnimalAvatar(
    id: 'avatar_bear',
    name: 'Highland Bear',
    assetPath: 'assets/avatars/bear.png',
  );
  static const AnimalAvatar deer = AnimalAvatar(
    id: 'avatar_deer',
    name: 'Mountain Deer',
    assetPath: 'assets/avatars/deer.png',
  );
  static const AnimalAvatar cat = AnimalAvatar(
    id: 'avatar_cat',
    name: 'Abyssinian Cat',
    assetPath: 'assets/avatars/cat.png',
  );

  /// Order shown in the picker. Ethiopian species lead, then the wider
  /// highland cast.
  static const List<AnimalAvatar> catalog = [
    wolf,
    lion,
    lovebird,
    ibex,
    gelada,
    monkey,
    owl,
    bear,
    deer,
    cat,
  ];

  static AnimalAvatar byId(String? id) => tryById(id) ?? wolf;

  /// Null for ids this build does not know, so callers can fall back to
  /// initials rather than showing the wrong animal.
  static AnimalAvatar? tryById(String? id) {
    if (id == null) return null;
    for (final avatar in catalog) {
      if (avatar.id == id) return avatar;
    }
    return null;
  }

  static String assetFor(String? id) => byId(id).assetPath;
}
