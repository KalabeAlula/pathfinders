import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/milestones/domain/shared_milestone.dart';
import 'package:pathfinders/features/milestones/presentation/milestone_copy.dart';

SharedMilestone _milestone({
  DateTime? startsAt,
  String? place,
  String? subtitle,
}) => SharedMilestone(
  id: 's1',
  title: 'Dinner together',
  date: DateTime(2026, 11, 20),
  kind: MilestoneKind.anniversary,
  startsAt: startsAt,
  place: place,
  subtitle: subtitle,
);

void main() {
  group('milestoneWhenLine', () {
    test('counts down the hours on the day of the event', () {
      final milestone = _milestone(
        startsAt: DateTime(2026, 11, 20, 19),
      );
      final now = DateTime(2026, 11, 20, 14, 40);

      expect(milestoneWhenLine(milestone, now), 'Today · in 4h 20m');
    });

    test('switches to minutes inside the last hour', () {
      final milestone = _milestone(
        startsAt: DateTime(2026, 11, 20, 19),
      );
      final now = DateTime(2026, 11, 20, 18, 25);

      expect(milestoneWhenLine(milestone, now), 'Today · in 35m');
    });

    test('says it is happening now shortly after the start', () {
      final milestone = _milestone(
        startsAt: DateTime(2026, 11, 20, 19),
      );

      expect(
        milestoneWhenLine(milestone, DateTime(2026, 11, 20, 19, 40)),
        'Happening now',
      );
    });

    test('gives the start clock once the moment has passed', () {
      final milestone = _milestone(
        startsAt: DateTime(2026, 11, 20, 9),
      );

      expect(
        milestoneWhenLine(milestone, DateTime(2026, 11, 20, 18)),
        'Started at 9:00 AM',
      );
    });

    test('names tomorrow instead of a date', () {
      final milestone = _milestone(
        startsAt: DateTime(2026, 11, 20, 19),
      );

      expect(
        milestoneWhenLine(milestone, DateTime(2026, 11, 19, 12)),
        'Tomorrow · 7:00 PM',
      );
    });

    test('keeps the date for later this week', () {
      final milestone = _milestone(
        startsAt: DateTime(2026, 11, 20, 19),
        place: 'Langano Lake',
      );

      expect(
        milestoneWhenLine(milestone, DateTime(2026, 11, 15, 10)),
        'Fri, Nov 20 · 7:00 PM',
      );
    });

    test('falls back to the day when no time was set', () {
      final milestone = _milestone();

      expect(
        milestoneWhenLine(milestone, DateTime(2026, 11, 15)),
        'Fri, Nov 20',
      );
    });
  });

  group('milestoneShareText', () {
    test('hands the crew the whole plan', () {
      final milestone = _milestone(
        startsAt: DateTime(2026, 11, 20, 19),
        place: 'Langano Lake',
      );

      expect(
        milestoneShareText(milestone),
        'Fri, Nov 20 at 7:00 PM · Langano Lake. Who\'s in?',
      );
    });

    test('skips a place that was not set', () {
      final milestone = _milestone(
        startsAt: DateTime(2026, 11, 20, 19),
      );

      expect(
        milestoneShareText(milestone),
        'Fri, Nov 20 at 7:00 PM. Who\'s in?',
      );
    });

    test('shares a date-only countdown without a clock time', () {
      final milestone = _milestone(place: 'Entoto');

      expect(
        milestoneShareText(milestone),
        'Fri, Nov 20 · Entoto. Who\'s in?',
      );
    });
  });
}
