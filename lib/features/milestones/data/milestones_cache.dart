import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/shared_milestone.dart';

/// Last known countdown list for one circle.
///
/// The cache lets the list render before the network answers, and keeps the
/// last good list visible when the first fetch fails after a restart.
class MilestonesCache {
  MilestonesCache(this._preferences, {required this.circleId});

  final SharedPreferences _preferences;
  final String circleId;

  String get _key => 'milestones.cache.$circleId';

  List<SharedMilestone>? read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! List) return null;

    final milestones = <SharedMilestone>[];
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        milestones.add(_decode(entry));
      } on Object {
        // Skip a single corrupt entry instead of losing the whole list.
        continue;
      }
    }
    return milestones;
  }

  Future<void> write(List<SharedMilestone> milestones) {
    final encoded = jsonEncode([
      for (final milestone in milestones) _encode(milestone),
    ]);
    return _preferences.setString(_key, encoded);
  }

  /// Drops the cached countdowns after the member leaves or the circle is
  /// deleted.
  Future<void> clear() => _preferences.remove(_key);

  static Map<String, Object?> _encode(SharedMilestone milestone) => {
    'id': milestone.id,
    'title': milestone.title,
    'date': _dateOnly(milestone.date),
    'kind': milestone.kind.name,
    'subtitle': milestone.subtitle,
  };

  static SharedMilestone _decode(Map<String, dynamic> json) => SharedMilestone(
    id: json['id'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    kind: MilestoneKind.values.firstWhere(
      (kind) => kind.name == json['kind'],
      orElse: () => MilestoneKind.goal,
    ),
    subtitle: json['subtitle'] as String?,
  );

  static String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
