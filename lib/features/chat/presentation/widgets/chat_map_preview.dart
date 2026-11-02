import '../../../../core/config/mapbox_config.dart';

/// A Static Images URL for the mini map inside a location bubble.
///
/// Returns null when no public Mapbox token is configured; the bubble then
/// falls back to a plain coordinate chip.
String? chatMapPreviewUrl({
  required double latitude,
  required double longitude,
  required bool dark,
  int width = 600,
  int height = 280,
}) {
  final token = MapboxConfig.accessToken.trim();
  if (token.isEmpty) return null;

  final style = dark ? 'mapbox/dark-v11' : 'mapbox/light-v11';
  final center =
      '${longitude.toStringAsFixed(5)},${latitude.toStringAsFixed(5)}';
  final pin = 'pin-s+2E7D5B($center)';
  final path = '/styles/v1/$style/static/$pin/$center,14/${width}x$height@2x';

  return Uri.https('api.mapbox.com', path, {'access_token': token}).toString();
}
