import 'animated_webp_sticker_io.dart'
    if (dart.library.js_interop) 'animated_webp_sticker_web.dart';

/// Platform-agnostic animated WebP sticker widget.
///
/// - **Web**: renders a native `<img>` element via `HtmlElementView.fromTagName`
///   so the browser decodes and animates WebP natively with zero `dart:io` or
///   CanvasKit overhead.
/// - **Mobile / Desktop**: downloads and caches the WebP with
///   `flutter_cache_manager` (`DefaultCacheManager`) and renders via
///   `Image.file(..., gaplessPlayback: true)` without `cacheWidth` /
///   `ResizeImage` so all animation frames are preserved.
typedef AnimatedWebpSticker = AnimatedWebpStickerImpl;
