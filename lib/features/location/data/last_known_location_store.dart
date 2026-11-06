import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/storage_providers.dart';
import '../domain/geo_point.dart';

/// The last fix this device saw, kept so the map has a centre to fly to
/// before the first satellite lock of a new session arrives.
class LastKnownLocationStore {
  const LastKnownLocationStore(this._preferences);

  final SharedPreferences _preferences;

  static const _latitudeKey = 'map.last_known_latitude';
  static const _longitudeKey = 'map.last_known_longitude';

  GeoPoint? read() {
    final latitude = _preferences.getDouble(_latitudeKey);
    final longitude = _preferences.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) return null;
    return GeoPoint(latitude: latitude, longitude: longitude);
  }

  Future<void> write(GeoPoint point) async {
    await _preferences.setDouble(_latitudeKey, point.latitude);
    await _preferences.setDouble(_longitudeKey, point.longitude);
  }
}

final lastKnownLocationStoreProvider = Provider<LastKnownLocationStore>(
  (ref) => LastKnownLocationStore(ref.watch(sharedPreferencesProvider)),
);
