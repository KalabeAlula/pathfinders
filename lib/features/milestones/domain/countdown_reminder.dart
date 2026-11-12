import 'dart:convert';

import '../../../core/utils/time_format.dart';
import 'shared_milestone.dart';

/// The heads-up the night before a countdown, rendered by the notification
/// shade so the circle still hears about tomorrow while the app is away.
class CountdownReminder {
  const CountdownReminder({
    required this.id,
    required this.milestoneId,
    required this.circleId,
    required this.title,
    required this.body,
    required this.payload,
    required this.scheduledAt,
  });

  /// Builds the reminder for [milestone], or null when there is nothing left
  /// to warn about: the date already arrived, or 18:00 came and went while the
  /// app was closed.
  static CountdownReminder? forMilestone({
    required SharedMilestone milestone,
    required String circleId,
    required String circleName,
    required DateTime now,
  }) {
    if (milestone.daysFrom(now) < 1) return null;

    // DateTime rolls day 0 back into the previous month on its own.
    final scheduledAt = DateTime(
      milestone.date.year,
      milestone.date.month,
      milestone.date.day - 1,
      eveningHour,
    );
    if (!scheduledAt.isAfter(now)) return null;

    return CountdownReminder(
      id: idFor(milestone.id),
      milestoneId: milestone.id,
      circleId: circleId,
      title: '${milestone.title} is tomorrow',
      body: _bodyFor(milestone, circleName),
      payload: jsonEncode({
        'kind': 'countdown',
        'circle_id': circleId,
        'milestone_id': milestone.id,
      }),
      scheduledAt: scheduledAt,
    );
  }

  /// Local time of the evening reminder, chosen so it lands after dinner and
  /// before anyone is asleep.
  static const eveningHour = 18;

  /// Stable across app runs so a replanned countdown replaces its own alarm
  /// instead of stacking a second one.
  static int idFor(String milestoneId) {
    var hash = 0x811c9dc5;
    for (final unit in milestoneId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  final int id;
  final String milestoneId;
  final String circleId;
  final String title;
  final String body;

  /// Carried with the notification so a tap can open the right circle later.
  final String payload;
  final DateTime scheduledAt;

  static String _bodyFor(SharedMilestone milestone, String circleName) {
    final place = milestone.place?.trim();
    final start = milestone.startsAt;
    final details = <String>[
      circleName,
      if (start != null) formatEventTime(start),
      if (place != null && place.isNotEmpty) place,
    ];
    if (details.length == 1) {
      return '$circleName · open the plan to sort the details';
    }
    return details.join(' · ');
  }
}
