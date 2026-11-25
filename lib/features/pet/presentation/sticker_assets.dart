import 'package:flutter/services.dart';

import '../domain/pet_mood.dart';

/// Default animated WebP path for [petId] and [mood]:
/// `assets/pets/<pet id>/<mood>_<index>.webp`.
String petStickerAssetPath(String petId, PetMood mood, {int index = 1}) =>
    'assets/pets/$petId/${mood.name}_$index.webp';

/// Which sticker files this build actually ships.
///
/// Resolution reads the asset manifest instead of a hand-written list, so
/// dropping additional `<mood>_<n>.webp` expressions under `assets/pets/<id>/`
/// lights them up with no code change.
class PetStickerAssets {
  PetStickerAssets._();

  static final Expando<Future<Set<String>>> _index = Expando();

  static Future<Set<String>> of(AssetBundle bundle) {
    return _index[bundle] ??= AssetManifest.loadFromAssetBundle(bundle)
        .then((manifest) => manifest.listAssets().toSet())
        .catchError((Object _) => <String>{});
  }

  /// All bundled expression paths for [petId] in [mood], sorted cleanly.
  static List<String> expressionsFor(
    Set<String> manifest,
    String petId,
    PetMood mood,
  ) {
    final prefix = 'assets/pets/$petId/${mood.name}_';
    final matches = manifest
        .where((path) => path.startsWith(prefix) && path.endsWith('.webp'))
        .toList()
      ..sort();
    return matches;
  }
}
