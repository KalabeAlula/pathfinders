/// How hard the location stream works, chosen from the phone's battery.
///
/// Sharing runs all day, so the interval widens as the battery drains: a
/// full phone tracks every few seconds, a nearly flat one only every couple
/// of minutes. [keepAlive] stays well inside the five-minute window the circle
/// uses to decide a member is offline, so someone who sits still keeps
/// looking live without waking the GPS.
class TelemetryCadence {
  const TelemetryCadence({
    required this.interval,
    required this.distanceFilter,
    required this.keepAlive,
  });

  /// Minimum time between fixes.
  final Duration interval;

  /// Metres of movement before the OS sends another fix.
  final double distanceFilter;

  /// Re-send the last fix this often while the member is not moving.
  final Duration keepAlive;

  static const charging = TelemetryCadence(
    interval: Duration(seconds: 10),
    distanceFilter: 10,
    keepAlive: Duration(seconds: 45),
  );

  static const healthy = TelemetryCadence(
    interval: Duration(seconds: 20),
    distanceFilter: 25,
    keepAlive: Duration(seconds: 60),
  );

  static const conserving = TelemetryCadence(
    interval: Duration(seconds: 45),
    distanceFilter: 50,
    keepAlive: Duration(seconds: 90),
  );

  static const low = TelemetryCadence(
    interval: Duration(seconds: 120),
    distanceFilter: 100,
    keepAlive: Duration(seconds: 150),
  );

  /// Battery and presence only, with no fix requested at all.
  static const batteryOnly = TelemetryCadence(
    interval: Duration(minutes: 5),
    distanceFilter: 0,
    keepAlive: Duration(seconds: 120),
  );

  static TelemetryCadence forBattery({
    required int? percent,
    required bool isCharging,
  }) {
    if (isCharging) return charging;
    if (percent == null) return healthy;
    if (percent > 40) return healthy;
    if (percent > 15) return conserving;
    return low;
  }

  @override
  bool operator ==(Object other) =>
      other is TelemetryCadence &&
      other.interval == interval &&
      other.distanceFilter == distanceFilter &&
      other.keepAlive == keepAlive;

  @override
  int get hashCode => Object.hash(interval, distanceFilter, keepAlive);
}
