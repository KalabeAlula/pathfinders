import 'animated_animal_avatar_io.dart'
    if (dart.library.html) 'animated_animal_avatar_web.dart';

/// Platform-agnostic animated avatar widget.
///
/// Loads animated WebP from Supabase Storage with caching.
/// Falls back to static PNG asset if offline or animatedUrl is null.
///
/// Usage:
///   AnimatedAnimalAvatar(
///     avatar: AnimalAvatar.cuddleBear,
///     size: 120,
///     animate: true,  // false for chat bubbles
///   )
typedef AnimatedAnimalAvatar = AnimatedAnimalAvatarImpl;
