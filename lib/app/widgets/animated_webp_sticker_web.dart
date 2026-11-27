import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

/// Web implementation rendering a native `<img>` tag via `HtmlElementView` so
/// the browser handles caching and animated WebP playback directly.
class AnimatedWebpStickerImpl extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: HtmlElementView.fromTagName(
        key: ValueKey('$url-$circular-${fit.name}'),
        tagName: 'img',
        onElementCreated: (Object element) {
          final img = element as JSObject;
          // Use the exact public HTTPS URL without crossOrigin='anonymous' so
          // the browser loads and animates the WebP directly.
          img.setProperty('src'.toJS, url.toJS);
          if (semanticLabel != null) {
            img.setProperty('alt'.toJS, semanticLabel!.toJS);
          }
          final style = img.getProperty<JSObject>('style'.toJS);
          style.setProperty('width'.toJS, '100%'.toJS);
          style.setProperty('height'.toJS, '100%'.toJS);
          style.setProperty(
            'objectFit'.toJS,
            (fit == BoxFit.cover ? 'cover' : 'contain').toJS,
          );
          style.setProperty('pointerEvents'.toJS, 'none'.toJS);
          if (circular) {
            style.setProperty('borderRadius'.toJS, '50%'.toJS);
          }
        },
      ),
    );
  }
}
