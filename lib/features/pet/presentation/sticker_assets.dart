import 'package:flutter/services.dart';

import '../domain/pet_mood.dart';

/// Default animated WebP path for [petId] and [mood]:
/// `assets/pets/<pet id>/<mood>_<index>.webp`.
String petStickerAssetPath(String petId, PetMood mood, {int index = 1}) =>
    'assets/pets/$petId/${mood.name}_$index.webp';

/// Which sticker files this build ships.
///
/// Synchronous lookup for the bundled 3-expression-per-mood WebP packs so
/// [AnimatedPetSticker] renders the animated asset on frame 1 without waiting
/// for an async manifest parse.
class PetStickerAssets {
  PetStickerAssets._();

  static const Set<String> _bundledPets = {
    'fox',
    'seagull',
    'dog',
    'orangutan',
  };

  static const int _expressionsPerMood = 3;

  static final Expando<Future<Set<String>>> _index = Expando();

  static Future<Set<String>> of(AssetBundle bundle) {
    return _index[bundle] ??= AssetManifest.loadFromAssetBundle(bundle)
        .then((manifest) => manifest.listAssets().toSet())
        .catchError((Object _) => <String>{});
  }

  /// All bundled expression paths for [petId] in [mood].
  static List<String> expressionsFor(String petId, PetMood mood) {
    if (!_bundledPets.contains(petId)) return const [];
    return [
      for (var i = 1; i <= _expressionsPerMood; i++)
        petStickerAssetPath(petId, mood, index: i),
    ];
  }
}
