// Web-specific implementation using native <img> elements for animated WebP.
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Web-only: Render animated WebP via native <img> element.
///
/// Flutter Web's CanvasKit renderer decodes only the first frame of animated
/// WebPs. Browsers natively animate .webp at 60fps, so we use HtmlElementView
/// with `pointer-events: none` to preserve Flutter's tap gesture handling.
class WebNativeImageSticker extends StatefulWidget {
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
  State<WebNativeImageSticker> createState() => _WebNativeImageStickerState();
}

class _WebNativeImageStickerState extends State<WebNativeImageSticker> {
  static final _registeredViews = <String, int>{};
  static int _nextViewId = 0;
  late final String _viewType;
  late String _currentAsset;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;

    // Create a unique viewType for each widget instance (not per asset)
    // so HtmlElementView updates properly when the asset changes.
    _viewType = 'animated-webp-${_nextViewId++}';

    if (kDebugMode) {
      debugPrint(
        '🎨 WebNativeImageSticker.initState: asset=${widget.asset}, viewType=$_viewType',
      );
    }

    // Register the platform view factory once per unique viewType.
    if (!_registeredViews.containsKey(_viewType)) {
      _registeredViews[_viewType] = _nextViewId;

      // Register the view factory with Flutter's platform view registry
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _createImageElement(_currentAsset),
      );

      if (kDebugMode) {
        debugPrint('✅ Registered view factory: $_viewType');
      }
    }
  }

  @override
  void didUpdateWidget(WebNativeImageSticker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When the asset changes (mood change, tap), we need to update the <img> src.
    // Since HtmlElementView doesn't support updating props, we rely on the
    // unique Key(resolvedAsset) in _AnimatedImageSticker to rebuild this widget.
    if (oldWidget.asset != widget.asset) {
      _currentAsset = widget.asset;

      if (kDebugMode) {
        debugPrint('🔄 Asset changed: ${oldWidget.asset} → ${widget.asset}');
      }
    }
  }

  web.HTMLImageElement _createImageElement(String asset) {
    // Fix #3: Use assetManager to get the correct URL for Flutter Web assets.
    // Flutter Web serves assets under assets/assets/... not assets/...
    final assetUrl = ui_web.assetManager.getAssetUrl(asset);

    if (kDebugMode) {
      debugPrint('🖼️  Creating <img>: asset=$asset, url=$assetUrl');
    }

    final img = web.HTMLImageElement()
      ..src = assetUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.pointerEvents =
          'none' // Let Flutter handle taps
      ..style.userSelect = 'none'
      ..style.display = 'block';

    return img;
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🎨 WebNativeImageSticker.build: asset=${widget.asset}');
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
