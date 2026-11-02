import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/memory_photo_providers.dart';

/// Opens the photo full-screen on a black backdrop, with pinch-to-zoom.
Future<void> showMemoryPhotoViewer(
  BuildContext context, {
  required String path,
  String? label,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierColor: Colors.black,
    builder: (_) => _MemoryPhotoViewer(path: path, label: label),
  );
}

class _MemoryPhotoViewer extends ConsumerWidget {
  const _MemoryPhotoViewer({required this.path, this.label});

  final String path;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(memoryPhotoUrlProvider(path));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: url.when(
              data: (value) => LayoutBuilder(
                builder: (context, constraints) {
                  final cacheWidth =
                      (constraints.maxWidth *
                              MediaQuery.devicePixelRatioOf(context))
                          .round();
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Image.network(
                        value,
                        fit: BoxFit.contain,
                        cacheWidth: cacheWidth,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                        errorBuilder: (context, error, stack) =>
                            const _ViewerError(),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (error, stack) => Center(
                child: _ViewerError(
                  onRetry: () => ref.invalidate(memoryPhotoUrlProvider(path)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  tooltip: 'Close photo',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
          if (label != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                    ),
                  ),
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: Colors.white54,
          ),
          const SizedBox(height: 8),
          const Text(
            'Could not load this photo.',
            style: TextStyle(color: Colors.white70),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
