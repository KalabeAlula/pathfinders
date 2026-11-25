// Stub implementation for non-web platforms (falls back to Image.asset).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Stub for non-web platforms. Falls back to regular Image.asset.
class WebNativeImageSticker extends StatelessWidget {
  const WebNativeImageSticker({
    super.key,
    required this.asset,
    required this.size,
    required this.fallback,
  });

  final String asset;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
        '⚠️  STUB WebNativeImageSticker called (should not happen on web!)',
      );
    }

    // On non-web platforms, use standard Image.asset (animated WebP works fine).
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
