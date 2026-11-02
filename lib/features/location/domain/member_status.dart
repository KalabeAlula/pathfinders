import 'geo_point.dart';
import 'privacy_mode.dart';

/// A moment-in-time telemetry snapshot for one member.
///
/// Coordinates arrive already masked by the server: an approximate mode is
/// pre-snapped to a coarse grid, and a paused mode carries no location at all.
/// Screens should never try to re-derive a precise point.
class MemberStatus {
  const MemberStatus({
    required this.userId,
    required this.location,
    required this.batteryPercent,
    required this.isCharging,
    required this.speedKph,
    required this.isOnline,
    required this.privacyMode,
    required this.updatedAt,
    this.arrivedAt,
  });

  final String userId;
  final GeoPoint? location;

  /// How stale a row may be before this member reads as offline.
  ///
  /// The slowest keepalive heartbeat is 2.5 minutes, so this leaves a full
  /// minute of slack for a slow request or a timer the OS suspended.
  static const Duration onlineWindow = Duration(minutes: 5);

  /// Matches the device-side speed deadband: anything slower is jitter.
  static const double movingThresholdKph = 3.6;

  /// Null when the device has not reported a level yet.
  final int? batteryPercent;
  final bool isCharging;
  final double speedKph;
  final bool isOnline;
  final PrivacyMode privacyMode;
  final DateTime updatedAt;

  /// When the member last arrived somewhere new; drives dwell copy.
  final DateTime? arrivedAt;

  bool get hasLocation => location != null;

  bool get isApproximate => privacyMode == PrivacyMode.approximate;

  bool get isPaused => privacyMode == PrivacyMode.paused;

  bool get isLowBattery => batteryPercent != null && batteryPercent! <= 20;

  bool get isMoving => speedKph >= movingThresholdKph;

  /// Whether the row is still fresh as of [now].
  ///
  /// [isOnline] is frozen at decode time, so screens that tick a clock should
  /// use this instead.
  bool isOnlineAt(DateTime now) =>
      now.toUtc().difference(updatedAt.toUtc()) <= onlineWindow;

  Duration? dwellTime(DateTime now) {
    final arrived = arrivedAt;
    if (arrived == null) return null;
    final duration = now.difference(arrived);
    return duration.isNegative ? Duration.zero : duration;
  }
}
