import 'package:shared_preferences/shared_preferences.dart';

/// The member's most recent map searches, newest first.
class SearchHistoryStore {
  SearchHistoryStore(this._preferences, {required this.userId});

  static const maxEntries = 5;

  final SharedPreferences _preferences;
  final String userId;

  String get _key => 'search.history.$userId';

  List<String> read() =>
      List.unmodifiable(_preferences.getStringList(_key) ?? const <String>[]);

  /// Moves [query] to the front, dropping an earlier spelling of the same
  /// search so the list does not fill up with duplicates.
  Future<void> remember(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return Future.value();

    final key = clean.toLowerCase();
    final updated = <String>[
      clean,
      for (final entry in _preferences.getStringList(_key) ?? const <String>[])
        if (entry.toLowerCase() != key) entry,
    ];

    return _preferences.setStringList(_key, updated.take(maxEntries).toList());
  }
}
