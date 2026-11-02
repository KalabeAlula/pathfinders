import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which destination trip this device has already announced an
/// arrival for, so restarts and GPS jitter cannot spam the crew chat.
class ArrivalStore {
  ArrivalStore(this._preferences);

  final SharedPreferences _preferences;

  String _key(String circleId) => 'navigation.arrived.$circleId';

  String? read(String circleId) => _preferences.getString(_key(circleId));

  Future<void> write(String circleId, String tripKey) =>
      _preferences.setString(_key(circleId), tripKey);

  Future<void> clear(String circleId) => _preferences.remove(_key(circleId));
}
