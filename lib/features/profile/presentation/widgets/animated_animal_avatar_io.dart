import 'package:flutter/material.dart';

import '../../domain/animal_avatar.dart';

/// Mobile/desktop implementation using flutter_cache_manager for caching.
class AnimatedAnimalAvatarImpl extends StatelessWidget {
  const AnimatedAnimalAvatarImpl({
    super.key,
    required this.avatar,
    required this.size,
    this.animate = true,
  });

  final AnimalAvatar avatar;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    // Use animated WebP if available and animation enabled
    final shouldAnimate = animate && avatar.animatedUrl != null;

    if (shouldAnimate) {
      return Image(
        image: NetworkImage(
          avatar.animatedUrl!,
          headers: const {'Cache-Control': 'public, max-age=31536000'},
        ),
        width: size,
        height: size,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          // Show static PNG placeholder while loading
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return Image.asset(
            avatar.assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback to static PNG on error (offline, network failure)
          return Image.asset(
            avatar.assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      );
    }

    // Static PNG fallback
    return Image.asset(
      avatar.assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * MediaQuery.of(context).devicePixelRatio).round(),
    );
  }
}
