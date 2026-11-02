import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/memory_photo_providers.dart';

/// Photo from the private bucket, backed by a short-lived signed URL.
///
/// The parent decides the box ([width] x [height]); the image fills it with
/// [fit]. When [onTap] is provided the photo becomes a button, used by the
/// detail screen to open the full-screen viewer.
class MemoryPhotoView extends ConsumerWidget {
  const MemoryPhotoView({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  final String path;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final url = ref.watch(memoryPhotoUrlProvider(path));
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.photo_rounded,
          size: 22,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : (width ?? 400);
            final boxHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : (height ?? boxWidth);
            final pixelRatio = MediaQuery.devicePixelRatioOf(context);
            final cacheWidth = (boxWidth * pixelRatio).round();
            final cacheHeight = (boxHeight * pixelRatio).round();
            return url.when(
              data: (value) => Image(
                // The fit policy caps both decoded dimensions while keeping
                // the photo's aspect ratio; the default exact policy would
                // stretch a photo that does not match the tile.
                image: ResizeImage(
                  NetworkImage(value),
                  width: cacheWidth,
                  height: cacheHeight,
                  policy: ResizeImagePolicy.fit,
                ),
                width: width,
                height: height,
                fit: fit,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
                errorBuilder: (context, error, stack) => placeholder,
              ),
              loading: () => placeholder,
              error: (error, stack) => placeholder,
            );
          },
        ),
      ),
    );

    if (onTap == null) return photo;
    return Semantics(
      button: true,
      label: 'Open photo',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: photo,
      ),
    );
  }
}
