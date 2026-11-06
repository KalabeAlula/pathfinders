import '../../../core/utils/time_format.dart';
import '../domain/shared_milestone.dart';

/// The day half of a countdown line, leaving the clock time for its own
/// badge: "Today · in 4h 20m", "Tomorrow", or "Sat, Nov 15".
String milestoneDayLine(SharedMilestone milestone, DateTime now) {
  final start = milestone.startsAt;
  final days = milestone.daysFrom(now);

  if (days == 0) {
    if (start == null) return 'Today';
    final left = start.difference(now);
    if (left.isNegative) {
      return left.abs() <= const Duration(hours: 3)
          ? 'Happening now'
          : 'Earlier today';
    }
    return 'Today · in ${_shortLeft(left)}';
  }
  if (days == 1) return 'Tomorrow';
  return formatMilestoneDate(milestone.date);
}

/// The full planning line, time included: "Today · in 4h 20m", "Tomorrow ·
/// 7:00 PM", or "Sat, Nov 15 · 7:00 PM".
String milestoneWhenLine(SharedMilestone milestone, DateTime now) {
  final start = milestone.startsAt;
  if (start == null) return milestoneDayLine(milestone, now);

  final time = formatEventTime(start);
  final days = milestone.daysFrom(now);
  if (days == 0) {
    final left = start.difference(now);
    return left.isNegative && left.abs() > const Duration(hours: 3)
        ? 'Started at $time'
        : milestoneDayLine(milestone, now);
  }
  if (days == 1) return 'Tomorrow · $time';
  return '${formatMilestoneDate(milestone.date)} · $time';
}

/// The one message that hands the whole plan to the crew.
String milestoneShareText(SharedMilestone milestone) {
  final when = milestoneWhenLineForShare(milestone);
  final place = milestone.place?.trim();
  final where = place == null || place.isEmpty ? '' : ' · $place';
  return '$when$where. Who\'s in?';
}

/// Absolute wording for chat: "Sat, Nov 15 at 7:00 PM".
String milestoneWhenLineForShare(SharedMilestone milestone) {
  final date = formatMilestoneDate(milestone.date);
  final start = milestone.startsAt;
  return start == null ? date : '$date at ${formatEventTime(start)}';
}

String _shortLeft(Duration left) {
  if (left.inMinutes < 60) {
    return '${left.inMinutes < 1 ? 1 : left.inMinutes}m';
  }
  if (left.inHours < 24) {
    final minutes = left.inMinutes.remainder(60);
    return minutes == 0 ? '${left.inHours}h' : '${left.inHours}h ${minutes}m';
  }
  final hours = left.inHours.remainder(24);
  return hours == 0 ? '${left.inDays}d' : '${left.inDays}d ${hours}h';
}
