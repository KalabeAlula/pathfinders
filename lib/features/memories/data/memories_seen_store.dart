import 'package:shared_preferences/shared_preferences.dart';

/// Persists when this device last opened a circle's memories gallery.
///
/// Storing the timestamp per circle keeps the dock badge honest after the app
/// restarts, matching the chat seen store.
class MemoriesSeenStore {
  MemoriesSeenStore(this._preferences);

  final SharedPreferences _preferences;

  String _key(String circleId) => 'memories.lastSeen.$circleId';

  DateTime? read(String circleId) {
    final raw = _preferences.getString(_key(circleId));
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  Future<void> write(String circleId, DateTime seenAt) {
    return _preferences.setString(
      _key(circleId),
      seenAt.toUtc().toIso8601String(),
    );
  }

  Future<void> clear(String circleId) => _preferences.remove(_key(circleId));
}
