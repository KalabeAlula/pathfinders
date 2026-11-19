/// Compile-time Giphy configuration.
///
/// The key is a public client key and safe to ship; it rides in the same
/// `mapbox.env.json` file as the map token
/// (`--dart-define-from-file=mapbox.env.json`). Without it the picker explains
/// that this build has no GIF search instead of failing on every open.
abstract final class GifConfig {
  static const apiKey = String.fromEnvironment('GIPHY_API_KEY');

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
