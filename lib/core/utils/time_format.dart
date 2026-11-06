import 'package:intl/intl.dart';

/// "2h 15m" style dwell time. Short enough for status tiles.
String formatDwell(Duration duration) {
  if (duration.inMinutes < 1) return 'just arrived';
  if (duration.inHours < 1) return '${duration.inMinutes}m';
  if (duration.inDays < 1) {
    final minutes = duration.inMinutes.remainder(60);
    return minutes == 0
        ? '${duration.inHours}h'
        : '${duration.inHours}h ${minutes}m';
  }
  final hours = duration.inHours.remainder(24);
  return hours == 0 ? '${duration.inDays}d' : '${duration.inDays}d ${hours}h';
}

String timeAgo(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(time);
  if (difference.isNegative || difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return DateFormat('MMM d').format(time);
}

String formatCountdown(int days) {
  if (days <= 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return 'In $days days';
}

String formatMilestoneDate(DateTime date) =>
    DateFormat('EEE, MMM d').format(date);

String formatDateLine(DateTime date) => DateFormat('EEEE, MMM d').format(date);

String formatVoiceNote(int seconds) {
  final minutesPart = seconds ~/ 60;
  final secondsPart = (seconds % 60).toString().padLeft(2, '0');
  return '$minutesPart:$secondsPart';
}

/// "850 m" / "4.2 km" for a driving route.
String formatRouteDistance(double meters) {
  if (!meters.isFinite || meters < 0) return '—';
  if (meters < 950) return '${meters.round()} m';
  final kilometers = meters / 1000;
  return kilometers < 10
      ? '${kilometers.toStringAsFixed(1)} km'
      : '${kilometers.round()} km';
}

/// Compact travel time for map chips: "6m", "1h 20m".
String formatRouteEta(Duration duration) {
  if (duration.inSeconds < 60) return 'now';
  final minutes = duration.inMinutes;
  if (minutes < 60) return '${minutes}m';
  final hours = duration.inHours;
  final rest = minutes.remainder(60);
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

/// The clock time a route lands, e.g. "4:35 PM".
String formatArrivalClock(DateTime eta) => DateFormat('h:mm a').format(eta);

/// Spoken-style countdown to the next maneuver: "Now", "In 250 m", "In 1.2 km".
String formatManeuverDistance(double meters) {
  if (!meters.isFinite || meters < 15) return 'Now';
  if (meters < 950) return 'In ${(meters / 10).round() * 10} m';
  final kilometers = meters / 1000;
  return 'In ${kilometers.toStringAsFixed(kilometers < 10 ? 1 : 0)} km';
}

/// The headline trip time, in full words: "14 min", "1 hr 20 min".
String formatTripTime(Duration duration) {
  if (duration.inSeconds < 60) return 'Under a minute';
  final minutes = duration.inMinutes;
  if (minutes < 60) return '$minutes min';
  final hours = duration.inHours;
  final rest = minutes.remainder(60);
  return rest == 0 ? '$hours hr' : '$hours hr $rest min';
}

/// The clock time an event starts, e.g. "7:00 PM".
String formatEventTime(DateTime start) => DateFormat('h:mm a').format(start);

String greetingFor(DateTime now) {
  if (now.hour < 5) return 'Still up';
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}
