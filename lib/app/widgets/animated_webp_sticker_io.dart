import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Mobile/desktop implementation using `flutter_cache_manager` + `Image.file`.
class AnimatedWebpStickerImpl extends StatefulWidget {
  const AnimatedWebpStickerImpl({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.circular = false,
    this.semanticLabel,
  });

  final String url;
  final double size;
  final Widget fallback;
  final BoxFit fit;
  final bool circular;
  final String? semanticLabel;

  @override
  State<AnimatedWebpStickerImpl> createState() =>
      _AnimatedWebpStickerImplState();
}

class _AnimatedWebpStickerImplState extends State<AnimatedWebpStickerImpl> {
  Future<File>? _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = DefaultCacheManager().getSingleFile(widget.url);
  }

  @override
  void didUpdateWidget(covariant AnimatedWebpStickerImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _fileFuture = DefaultCacheManager().getSingleFile(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<File>(
        future: _fileFuture,
        builder: (context, snapshot) {
          final file = snapshot.data;
          if (file == null) return widget.fallback;

          // Never pass cacheWidth/ResizeImage: resizing an animated WebP
          // flattens it to a single frame in Flutter's image codec.
          Widget image = Image.file(
            file,
            width: widget.size,
            height: widget.size,
            fit: widget.fit,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            semanticLabel: widget.semanticLabel,
            errorBuilder: (_, _, _) => widget.fallback,
          );
          if (widget.circular) {
            image = ClipOval(child: image);
          }
          return image;
        },
      ),
    );
  }
}
