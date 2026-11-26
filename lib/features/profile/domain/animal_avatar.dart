/// The curated animal portraits a member can wear across the app.
///
/// Ids are stored in `profiles.avatar_id`, so they must stay stable even if an
/// asset is redrawn. [byId] always answers with a usable avatar so a stale or
/// missing id never leaves a pin or header blank.
///
/// Supports both legacy Ethiopian animal avatars (static PNGs) and new animated
/// Fortnite-style character avatars (animated WebPs from Supabase Storage).
class AnimalAvatar {
  const AnimalAvatar({
    required this.id,
    required this.name,
    required this.assetPath,
    this.animatedUrl,
    this.isLegacy = false,
  });

  final String id;
  final String name;
  final String assetPath; // Static PNG for Mapbox/offline/placeholder
  final String? animatedUrl; // Animated WebP URL from Supabase Storage
  final bool isLegacy; // True for old Ethiopian animals

  static const String fallbackId = 'cuddle_bear';
  static const String _supabaseUrl = 'https://ijqweyrwyfmtkfsscarg.supabase.co';
  static const String _storagePath =
      '/storage/v1/object/public/avatar-stickers';

  // ========== LEGACY ETHIOPIAN ANIMALS (backward compatibility) ==========
  static const AnimalAvatar wolf = AnimalAvatar(
    id: 'avatar_wolf',
    name: 'Simien Wolf',
    assetPath: 'assets/avatars/wolf.png',
    isLegacy: true,
  );
  static const AnimalAvatar lion = AnimalAvatar(
    id: 'avatar_lion',
    name: 'Golden Lion',
    assetPath: 'assets/avatars/lion.png',
    isLegacy: true,
  );
  static const AnimalAvatar lovebird = AnimalAvatar(
    id: 'avatar_lovebird',
    name: 'Lovebird',
    assetPath: 'assets/avatars/lovebird.png',
    isLegacy: true,
  );
  static const AnimalAvatar ibex = AnimalAvatar(
    id: 'avatar_ibex',
    name: 'Walia Ibex',
    assetPath: 'assets/avatars/ibex.png',
    isLegacy: true,
  );
  static const AnimalAvatar gelada = AnimalAvatar(
    id: 'avatar_gelada',
    name: 'Gelada',
    assetPath: 'assets/avatars/gelada.png',
    isLegacy: true,
  );
  static const AnimalAvatar monkey = AnimalAvatar(
    id: 'avatar_monkey',
    name: 'Bale Monkey',
    assetPath: 'assets/avatars/monkey.png',
    isLegacy: true,
  );
  static const AnimalAvatar owl = AnimalAvatar(
    id: 'avatar_owl',
    name: 'Bubo Owl',
    assetPath: 'assets/avatars/owl.png',
    isLegacy: true,
  );
  static const AnimalAvatar bear = AnimalAvatar(
    id: 'avatar_bear',
    name: 'Highland Bear',
    assetPath: 'assets/avatars/bear.png',
    isLegacy: true,
  );
  static const AnimalAvatar deer = AnimalAvatar(
    id: 'avatar_deer',
    name: 'Mountain Deer',
    assetPath: 'assets/avatars/deer.png',
    isLegacy: true,
  );
  static const AnimalAvatar cat = AnimalAvatar(
    id: 'avatar_cat',
    name: 'Abyssinian Cat',
    assetPath: 'assets/avatars/cat.png',
    isLegacy: true,
  );

  // ========== NEW ANIMATED FORTNITE-STYLE AVATARS ==========
  static const AnimalAvatar cuddleBear = AnimalAvatar(
    id: 'cuddle_bear',
    name: 'Cuddle Bear',
    assetPath: 'assets/avatars/converted/fortnite_01.png',
    animatedUrl: '$_supabaseUrl$_storagePath/cuddle_bear.webp',
  );
  static const AnimalAvatar techBandit = AnimalAvatar(
    id: 'tech_bandit',
    name: 'Tech Bandit',
    assetPath: 'assets/avatars/converted/fortnite_02.png',
    animatedUrl: '$_supabaseUrl$_storagePath/tech_bandit.webp',
  );
  static const AnimalAvatar darkKnight = AnimalAvatar(
    id: 'dark_knight',
    name: 'Dark Knight',
    assetPath: 'assets/avatars/converted/fortnite_03.png',
    animatedUrl: '$_supabaseUrl$_storagePath/dark_knight.webp',
  );
  static const AnimalAvatar roboSoldier = AnimalAvatar(
    id: 'robo_soldier',
    name: 'Robo Soldier',
    assetPath: 'assets/avatars/converted/fortnite_04.png',
    animatedUrl: '$_supabaseUrl$_storagePath/robo_soldier.webp',
  );
  static const AnimalAvatar partyKing = AnimalAvatar(
    id: 'party_king',
    name: 'Party King',
    assetPath: 'assets/avatars/converted/fortnite_05.png',
    animatedUrl: '$_supabaseUrl$_storagePath/party_king.webp',
  );
  static const AnimalAvatar bushRanger = AnimalAvatar(
    id: 'bush_ranger',
    name: 'Bush Ranger',
    assetPath: 'assets/avatars/converted/fortnite_06.png',
    animatedUrl: '$_supabaseUrl$_storagePath/bush_ranger.webp',
  );
  static const AnimalAvatar skullTrooper = AnimalAvatar(
    id: 'skull_trooper',
    name: 'Skull Trooper',
    assetPath: 'assets/avatars/converted/fortnite_07.png',
    animatedUrl: '$_supabaseUrl$_storagePath/skull_trooper.webp',
  );
  static const AnimalAvatar tomatoHead = AnimalAvatar(
    id: 'tomato_head',
    name: 'Tomato Head',
    assetPath: 'assets/avatars/converted/fortnite_08.png',
    animatedUrl: '$_supabaseUrl$_storagePath/tomato_head.webp',
  );
  static const AnimalAvatar tacOps = AnimalAvatar(
    id: 'tac_ops',
    name: 'Tac Ops',
    assetPath: 'assets/avatars/converted/fortnite_09.png',
    animatedUrl: '$_supabaseUrl$_storagePath/tac_ops.webp',
  );
  static const AnimalAvatar outlaw = AnimalAvatar(
    id: 'outlaw',
    name: 'Outlaw',
    assetPath: 'assets/avatars/converted/fortnite_10.png',
    animatedUrl: '$_supabaseUrl$_storagePath/outlaw.webp',
  );
  static const AnimalAvatar iceMonk = AnimalAvatar(
    id: 'ice_monk',
    name: 'Ice Monk',
    assetPath: 'assets/avatars/converted/fortnite_11.png',
    animatedUrl: '$_supabaseUrl$_storagePath/ice_monk.webp',
  );
  static const AnimalAvatar loveRanger = AnimalAvatar(
    id: 'love_ranger',
    name: 'Love Ranger',
    assetPath: 'assets/avatars/converted/fortnite_12.png',
    animatedUrl: '$_supabaseUrl$_storagePath/love_ranger.webp',
  );
  static const AnimalAvatar dabChampion = AnimalAvatar(
    id: 'dab_champion',
    name: 'Dab Champion',
    assetPath: 'assets/avatars/converted/fortnite_13.png',
    animatedUrl: '$_supabaseUrl$_storagePath/dab_champion.webp',
  );
  static const AnimalAvatar astroAce = AnimalAvatar(
    id: 'astro_ace',
    name: 'Astro Ace',
    assetPath: 'assets/avatars/converted/fortnite_14.png',
    animatedUrl: '$_supabaseUrl$_storagePath/astro_ace.webp',
  );
  static const AnimalAvatar bunnyBrawler = AnimalAvatar(
    id: 'bunny_brawler',
    name: 'Bunny Brawler',
    assetPath: 'assets/avatars/converted/fortnite_15.png',
    animatedUrl: '$_supabaseUrl$_storagePath/bunny_brawler.webp',
  );
  static const AnimalAvatar blueHoodie = AnimalAvatar(
    id: 'blue_hoodie',
    name: 'Blue Hoodie',
    assetPath: 'assets/avatars/converted/fortnite_16.png',
    animatedUrl: '$_supabaseUrl$_storagePath/blue_hoodie.webp',
  );
  static const AnimalAvatar goGo = AnimalAvatar(
    id: 'go_go',
    name: 'Go Go',
    assetPath: 'assets/avatars/converted/fortnite_17.png',
    animatedUrl: '$_supabaseUrl$_storagePath/go_go.webp',
  );
  static const AnimalAvatar grumpyWitch = AnimalAvatar(
    id: 'grumpy_witch',
    name: 'Grumpy Witch',
    assetPath: 'assets/avatars/converted/fortnite_18.png',
    animatedUrl: '$_supabaseUrl$_storagePath/grumpy_witch.webp',
  );
  static const AnimalAvatar gingerbread = AnimalAvatar(
    id: 'gingerbread',
    name: 'Gingerbread',
    assetPath: 'assets/avatars/converted/fortnite_19.png',
    animatedUrl: '$_supabaseUrl$_storagePath/gingerbread.webp',
  );
  static const AnimalAvatar llamaLoot = AnimalAvatar(
    id: 'llama_loot',
    name: 'Llama Loot',
    assetPath: 'assets/avatars/converted/fortnite_20.png',
    animatedUrl: '$_supabaseUrl$_storagePath/llama_loot.webp',
  );
  static const AnimalAvatar scout = AnimalAvatar(
    id: 'scout',
    name: 'Scout',
    assetPath: 'assets/avatars/converted/fortnite_21.png',
    animatedUrl: '$_supabaseUrl$_storagePath/scout.webp',
  );
  static const AnimalAvatar hypeDancer = AnimalAvatar(
    id: 'hype_dancer',
    name: 'Hype Dancer',
    assetPath: 'assets/avatars/converted/fortnite_22.png',
    animatedUrl: '$_supabaseUrl$_storagePath/hype_dancer.webp',
  );
  static const AnimalAvatar cashGrab = AnimalAvatar(
    id: 'cash_grab',
    name: 'Cash Grab',
    assetPath: 'assets/avatars/converted/fortnite_23.png',
    animatedUrl: '$_supabaseUrl$_storagePath/cash_grab.webp',
  );

  /// Catalog of all 33 avatars (23 new + 10 legacy).
  /// New animated avatars shown first in picker.
  static const List<AnimalAvatar> catalog = [
    // New animated characters (shown in picker)
    cuddleBear, techBandit, darkKnight, roboSoldier, partyKing, bushRanger,
    skullTrooper, tomatoHead, tacOps, outlaw, iceMonk, loveRanger,
    dabChampion, astroAce, bunnyBrawler, blueHoodie, goGo, grumpyWitch,
    gingerbread, llamaLoot, scout, hypeDancer, cashGrab,
    // Legacy (not shown in picker, but resolved by ID for existing users)
    wolf, lion, lovebird, ibex, gelada, monkey, owl, bear, deer, cat,
  ];

  static AnimalAvatar byId(String? id) => tryById(id) ?? cuddleBear;

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
