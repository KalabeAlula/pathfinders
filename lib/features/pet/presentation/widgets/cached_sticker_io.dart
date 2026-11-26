import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Mobile/Desktop implementation using flutter_cache_manager.
///
/// Downloads and caches the WebP to device storage, then renders with Image.file.
/// Uses gaplessPlayback for smooth animated WebP playback without flicker.
class CachedNetworkStickerImpl extends StatelessWidget {
  const CachedNetworkStickerImpl({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  final String url;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: DefaultCacheManager().getSingleFile(url),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return SizedBox(
            width: size,
            height: size,
            child: Image.file(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          );
        }

        // Show fallback while loading or on error
        return fallback;
      },
    );
  }
}
