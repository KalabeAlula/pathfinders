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

  Future<String> signedUrl(String path) async {
    final now = DateTime.now();
    final cached = _cache[path];
    if (cached != null && cached.expiresAt.isAfter(now)) return cached.url;

    final url = await _client.storage
        .from(_bucket)
        .createSignedUrl(path, _lifetimeSeconds);
    _cache[path] = _SignedPhoto(url: url, expiresAt: now.add(_reuseFor));
    return url;
  }

  void forget(String path) => _cache.remove(path);
}

class _SignedPhoto {
  const _SignedPhoto({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
