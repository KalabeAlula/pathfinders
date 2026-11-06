import '../../../core/utils/time_format.dart';
import '../domain/shared_milestone.dart';

/// The planning line under a countdown: "Today · in 4h 20m", "Tomorrow ·
/// 7:00 PM", or "Sat, Nov 15 · 7:00 PM".
String milestoneWhenLine(SharedMilestone milestone, DateTime now) {
  final start = milestone.startsAt;
  final time = start == null ? null : formatEventTime(start);
  final days = milestone.daysFrom(now);

  if (days == 0) {
    if (start == null) return 'Today';
    final left = start.difference(now);
    if (left.isNegative) {
      return left.abs() <= const Duration(hours: 3)
          ? 'Happening now'
          : 'Started at $time';
    }
    return 'Today · in ${_shortLeft(left)}';
  }
  if (days == 1) return time == null ? 'Tomorrow' : 'Tomorrow · $time';
  final date = formatMilestoneDate(milestone.date);
  return time == null ? date : '$date · $time';
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
