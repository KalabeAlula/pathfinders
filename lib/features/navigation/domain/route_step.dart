import '../../location/domain/geo_point.dart';

/// The kind of movement a Directions step asks for.
///
/// Mapbox's raw maneuver vocabulary is collapsed into the handful of shapes
/// the banner can draw, so the UI never has to know the API strings.
enum ManeuverKind {
  depart,
  turnLeft,
  turnRight,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  uTurn,
  straight,
  roundabout,
  merge,
  forkLeft,
  forkRight,
  rampLeft,
  rampRight,
  arrive,
}

/// One leg of a Directions route: the maneuver that starts it, the road it
/// follows, and how long it is.
class RouteStep {
  const RouteStep({
    required this.kind,
    required this.roadName,
    required this.distanceMeters,
    required this.duration,
    required this.location,
    this.exitNumber,
  });

  final ManeuverKind kind;
  final String roadName;
  final double distanceMeters;
  final Duration duration;

  /// The maneuver point, which is also where this step begins.
  final GeoPoint location;

  /// Roundabout exit, when the step is a roundabout.
  final int? exitNumber;

  bool get isArrival => kind == ManeuverKind.arrive;

  /// The instruction a person would expect to hear, e.g.
  /// "Turn left onto Bole Road".
  String get instruction {
    final road = roadName.trim();
    final onto = road.isEmpty ? '' : ' onto $road';

    return switch (kind) {
      ManeuverKind.depart => road.isEmpty ? 'Head out' : 'Head out on $road',
      ManeuverKind.turnLeft => 'Turn left$onto',
      ManeuverKind.turnRight => 'Turn right$onto',
      ManeuverKind.slightLeft => 'Bear left$onto',
      ManeuverKind.slightRight => 'Bear right$onto',
      ManeuverKind.sharpLeft => 'Sharp left$onto',
      ManeuverKind.sharpRight => 'Sharp right$onto',
      ManeuverKind.uTurn => 'Make a U-turn$onto',
      ManeuverKind.straight => road.isEmpty ? 'Continue' : 'Continue on $road',
      ManeuverKind.roundabout => exitNumber == null
          ? 'Enter the roundabout$onto'
          : 'Take exit $exitNumber at the roundabout$onto',
      ManeuverKind.merge => 'Merge$onto',
      ManeuverKind.forkLeft => 'Keep left$onto',
      ManeuverKind.forkRight => 'Keep right$onto',
      ManeuverKind.rampLeft => 'Take the left ramp$onto',
      ManeuverKind.rampRight => 'Take the right ramp$onto',
      ManeuverKind.arrive => road.isEmpty
          ? 'Arrive at your destination'
          : 'Arrive at $road',
    };
  }
}
