import 'package:flutter/material.dart';

import '../../domain/ethiopian_pet.dart';

/// Circular badge for an Ethiopian companion. Falls back to the species emoji
/// if the bundled artwork cannot be decoded.
class PetAvatar extends StatelessWidget {
  const PetAvatar({super.key, required this.pet, this.size = 42});

  final EthiopianPet pet;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          pet.avatarAsset,
          width: size,
          height: size,
          cacheWidth: cacheWidth,
          fit: BoxFit.cover,
          semanticLabel: pet.commonName,
          errorBuilder: (_, _, _) => ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: Center(
              child: Text(pet.emoji, style: TextStyle(fontSize: size * 0.48)),
            ),
          ),
        ),
      ),
    );
  }
}
