enum MilestoneKind { birthday, anniversary, trip, goal }

class SharedMilestone {
  const SharedMilestone({
    required this.id,
    required this.title,
    required this.date,
    required this.kind,
    this.subtitle,
  });

  final String id;
  final String title;
  final DateTime date;
  final MilestoneKind kind;
  final String? subtitle;

  /// Whole calendar days remaining. Negative values mean the date has passed.
  int daysFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }
}
