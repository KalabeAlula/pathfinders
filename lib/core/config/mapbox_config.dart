/// Compile-time Mapbox configuration.
///
/// The app only needs the public `pk.` token. Pass it with
/// `--dart-define-from-file=mapbox.env.json` (see that file in the project
/// root). A secret `sk.` token is never read here: it would ship inside the
/// binary and is only for SDK dependency downloads.
abstract final class MapboxConfig {
  static const accessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  static bool get isConfigured => accessToken.trim().isNotEmpty;
}
