import 'package:flutter/material.dart';

import '../../../../app/widgets/animated_webp_sticker.dart';
import '../../domain/animal_avatar.dart';

/// Platform-aware animated avatar widget using the shared [AnimatedWebpSticker]:
/// - Mobile/Desktop: `flutter_cache_manager` + `Image.file(..., gaplessPlayback: true)`
/// - Web: native `<img>` via `HtmlElementView.fromTagName` with `border-radius: 50%`
class AnimatedAnimalAvatar extends StatelessWidget {
  const AnimatedAnimalAvatar({
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
    final placeholder = Image.asset(
      avatar.assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      semanticLabel: avatar.name,
    );

    final url = avatar.animatedUrl;
    if (animate && url != null) {
      return AnimatedWebpSticker(
        url: url,
        size: size,
        fit: BoxFit.cover,
        circular: true,
        semanticLabel: avatar.name,
        fallback: placeholder,
      );
    }

    return placeholder;
  }
}
