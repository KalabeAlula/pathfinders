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
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          avatar.assetPath,
          width: size,
          height: size,
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
        ),
      ),
    );
  }
}
