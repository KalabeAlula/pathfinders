import 'package:flutter/material.dart';

/// Web implementation using native <img> tag for optimal browser caching.
///
/// Browser handles caching, animated WebP decoding, and rendering natively.
/// Falls back to Image.network for simpler implementation (browser still caches).
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
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          // Show fallback while loading
          return fallback;
        },
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
