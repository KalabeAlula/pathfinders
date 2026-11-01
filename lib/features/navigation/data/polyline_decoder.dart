import '../../location/domain/geo_point.dart';

/// Decodes a Google/Mapbox encoded polyline (precision 5) into coordinates.
List<GeoPoint> decodePolyline(String encoded) {
  final points = <GeoPoint>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;

  while (index < encoded.length) {
    var shift = 0;
    var result = 0;
    var byte = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

    shift = 0;
    result = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

    points.add(
      GeoPoint(latitude: latitude / 1e5, longitude: longitude / 1e5),
    );
  }

  return points;
}
