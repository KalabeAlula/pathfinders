import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which group the member last had open, per account.
///
/// The id is cosmetic state: it never grants access, and an id that no longer
/// matches a membership is ignored in favour of the oldest group.
class ActiveCircleStore {
  ActiveCircleStore(this._preferences);

  final SharedPreferences _preferences;

  String _key(String userId) => 'active.circle.$userId';

  String? read(String userId) => _preferences.getString(_key(userId));

  Future<void> write(String userId, String circleId) {
    return _preferences.setString(_key(userId), circleId);
  }

  Future<void> clear(String userId) => _preferences.remove(_key(userId));
}
