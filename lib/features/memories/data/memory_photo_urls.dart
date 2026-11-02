import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Mints short-lived download URLs for photos in the private bucket.
///
/// URLs are reused for most of their lifetime so a rebuilding feed does not
/// mint one per frame. Nothing is persisted: a restart signs afresh, which
/// also keeps a leaked URL short-lived.
class MemoryPhotoUrls {
  MemoryPhotoUrls(this._client);

  final sb.SupabaseClient _client;

  static const _bucket = 'memories';
  static const _lifetimeSeconds = 3600;
  static const _reuseFor = Duration(minutes: 50);

  final _cache = <String, _SignedPhoto>{};
  final _pending = <String, Future<String>>{};

  Future<String> signedUrl(String path) {
    final now = DateTime.now();
    final cached = _cache[path];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return Future.value(cached.url);
    }

    // A scrolling feed can ask for the same photo several times in one frame;
    // share one signing request instead of minting a URL per tile.
    final pending = _pending[path];
    if (pending != null) return pending;

    final request = _mint(path);
    _pending[path] = request;
    return request.whenComplete(() {
      if (identical(_pending[path], request)) {
        _pending.remove(path);
      }
    });
  }

  Future<String> _mint(String path) async {
    final url = await _client.storage
        .from(_bucket)
        .createSignedUrl(path, _lifetimeSeconds);
    _cache[path] = _SignedPhoto(
      url: url,
      expiresAt: DateTime.now().add(_reuseFor),
    );
    return url;
  }

  void forget(String path) {
    _cache.remove(path);
    _pending.remove(path);
  }
}

class _SignedPhoto {
  const _SignedPhoto({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
