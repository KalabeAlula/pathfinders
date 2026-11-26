import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/pet_mood.dart';

/// Supabase Storage public URL for [petId] and [mood] animated WebP sticker.
///
/// Falls back to a safe placeholder URL for unit tests where Supabase isn't initialized.
String petStickerUrl(String petId, PetMood mood, {int index = 1}) {
  try {
    final client = Supabase.instance.client;
    return client.storage
        .from('pet-stickers')
        .getPublicUrl('$petId/${mood.name}_$index.webp');
  } catch (_) {
    // Fallback for unit tests where Supabase isn't initialized
    return 'https://placeholder.supabase.co/storage/v1/object/public/pet-stickers/$petId/${mood.name}_$index.webp';
  }
}

/// Legacy asset path for static PNG avatars (still bundled).
String petAvatarAssetPath(String petId) => 'assets/pets/$petId.png';

/// Which sticker URLs to load for each pet and mood.
///
/// All animated WebP stickers are now hosted in Supabase Storage (pet-stickers bucket).
/// Only the 4 static PNG portraits remain bundled as local assets.
class PetStickerAssets {
  PetStickerAssets._();

  static const Set<String> _knownPets = {'fox', 'seagull', 'dog', 'orangutan'};

  static const int _expressionsPerMood = 3;

  /// All Supabase Storage URLs for [petId] in [mood].
  ///
  /// Returns 3 URLs for every known pet × mood combination, synchronously.
  static List<String> expressionsFor(String petId, PetMood mood) {
    if (!_knownPets.contains(petId)) return const [];
    return [
      for (var i = 1; i <= _expressionsPerMood; i++)
        petStickerUrl(petId, mood, index: i),
    ];
  }
}
