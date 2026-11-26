import 'cached_sticker_io.dart'
    if (dart.library.html) 'cached_sticker_web.dart';

/// Platform-agnostic cached network sticker.
///
/// Automatically uses the correct implementation:
/// - Mobile/Desktop: flutter_cache_manager + Image.file
/// - Web: Image.network with browser caching
typedef CachedNetworkSticker = CachedNetworkStickerImpl;
