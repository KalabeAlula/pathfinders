enum MilestoneKind { birthday, anniversary, trip, goal }

class SharedMilestone {
  const SharedMilestone({
    required this.id,
    required this.title,
    required this.date,
    required this.kind,
    this.subtitle,
    this.startsAt,
    this.place,
  });

  final String id;
  final String title;
  final DateTime date;
  final MilestoneKind kind;
  final String? subtitle;

  /// Date plus clock time, when the circle agreed on one.
  final DateTime? startsAt;

  /// Where the circle is meeting, when it was noted.
  final String? place;

  /// Orders same-day countdowns by their start time.
  DateTime get sortKey => startsAt ?? date;

  SharedMilestone copyWith({String? place}) => SharedMilestone(
    id: id,
    title: title,
    date: date,
    kind: kind,
    subtitle: subtitle,
    startsAt: startsAt,
    place: place ?? this.place,
  );

  /// Whole calendar days remaining. Negative values mean the date has passed.
  int daysFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }
}
