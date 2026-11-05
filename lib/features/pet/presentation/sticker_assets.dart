import 'package:flutter/services.dart';

import '../domain/pet_mood.dart';

/// Where a pet's vector sticker for [mood] belongs:
/// `assets/pets/<pet id>/<mood>.json`.
///
/// Stickers are transparent, full-bleed art sized to the square, so the
/// widget can swap them in without changing its layout.
String petStickerAssetPath(String petId, PetMood mood) =>
    'assets/pets/$petId/${mood.name}.json';

/// Which sticker files this build actually ships.
///
/// Resolution reads the asset manifest instead of a hand-written list, so
/// dropping a new Lottie file under `assets/pets/` lights that state up with
/// no code change, and everything else keeps the procedural portrait.
class PetStickerAssets {
  PetStickerAssets._();

  static final Expando<Future<Set<String>>> _index = Expando();

  static Future<Set<String>> of(AssetBundle bundle) {
    return _index[bundle] ??= AssetManifest.loadFromAssetBundle(bundle)
        .then((manifest) => manifest.listAssets().toSet())
        .catchError((Object _) => <String>{});
  }
}
