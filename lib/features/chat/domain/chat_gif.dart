/// Giphy is the only GIF source the app renders: messages store a plain URL,
/// and accepting arbitrary hosts would let any member point a bubble at a
/// tracker or an oversized asset.
bool isAllowedGifUrl(String? value) {
  if (value == null) return false;
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.path.length <= 1) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host == 'giphy.com' || host.endsWith('.giphy.com');
}
