import 'package:flutter/material.dart';

import '../../domain/animal_avatar.dart';

/// Circular animal portrait used by the profile header, picker tiles, and
/// member avatars.
class AnimalAvatarView extends StatelessWidget {
  const AnimalAvatarView({
    super.key,
    required this.avatarId,
    this.size = 56,
    this.fallbackInitials = '?',
  });

  final String avatarId;
  final double size;

  /// Shown only if the bundled artwork cannot be decoded.
  final String fallbackInitials;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatar = AnimalAvatar.byId(avatarId);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return ClipOval(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Decode at the size the parent actually gives the avatar: the
          // picker stretches it to its grid tile, which is much larger than
          // the nominal [size], and a 56 px decode upscaled there is blurry.
          final side =
              constraints.hasBoundedWidth && constraints.hasBoundedHeight
              ? constraints.biggest.shortestSide
              : size;
          final pixels = (side * dpr).round();
          return Image.asset(
            avatar.assetPath,
            width: side,
            height: side,
            cacheWidth: pixels,
            fit: BoxFit.cover,
            semanticLabel: avatar.name,
            errorBuilder: (_, _, _) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Center(
                child: Text(
                  fallbackInitials,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
