import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/milestones/domain/countdown_reminder.dart';
import 'package:pathfinders/features/milestones/domain/shared_milestone.dart';

void main() {
  SharedMilestone milestone({
    String id = 'm1',
    String title = 'Dome days',
    DateTime? date,
    DateTime? startsAt,
    String? place,
  }) {
    return SharedMilestone(
      id: id,
      title: title,
      date: date ?? DateTime(2026, 11, 20),
      kind: MilestoneKind.trip,
      startsAt: startsAt,
      place: place,
    );
  }

  CountdownReminder? build(SharedMilestone plan, {DateTime? now}) {
    return CountdownReminder.forMilestone(
      milestone: plan,
      circleId: 'c1',
      circleName: 'Cake Lovers',
      now: now ?? DateTime(2026, 11, 12, 10),
    );
  }

  test('warns the evening before at 18:00 local', () {
    final reminder = build(milestone())!;

    expect(reminder.scheduledAt, DateTime(2026, 11, 19, 18));
    expect(reminder.title, 'Dome days is tomorrow');
  });

  test('rolls the reminder back across a month boundary', () {
    final reminder = build(
      milestone(
        date: DateTime(2027, 1, 1),
        startsAt: DateTime(2027, 1, 1, 20),
        place: 'Bole',
      ),
    )!;

    expect(reminder.scheduledAt, DateTime(2026, 12, 31, 18));
    expect(reminder.body, 'Cake Lovers · 8:00 PM · Bole');
  });

  test('body reads circle, time, and place only when they exist', () {
    expect(
      build(milestone(startsAt: DateTime(2026, 11, 20, 19)))!.body,
      'Cake Lovers · 7:00 PM',
    );
    expect(
      build(milestone(place: '  Gast Mall  '))!.body,
      'Cake Lovers · Gast Mall',
    );
    expect(
      build(milestone())!.body,
      'Cake Lovers · open the plan to sort the details',
    );
  });

  test('payload carries the countdown for tap routing', () {
    final reminder = build(milestone())!;

    expect(jsonDecode(reminder.payload), {
      'kind': 'countdown',
      'circle_id': 'c1',
      'milestone_id': 'm1',
    });
  });

  test('tap routing reads its own payload and ignores the rest', () {
    final tap = countdownTapFromPayload(build(milestone())!.payload)!;

    expect(tap.circleId, 'c1');
    expect(tap.milestoneId, 'm1');
    expect(countdownTapFromPayload(null), isNull);
    expect(countdownTapFromPayload('not json'), isNull);
    expect(
      countdownTapFromPayload(jsonEncode({'kind': 'chat', 'circle_id': 'c1'})),
      isNull,
    );
    expect(
      countdownTapFromPayload(
        jsonEncode({'kind': 'countdown', 'circle_id': 'c1'}),
      ),
      isNull,
    );
    expect(
      countdownTapFromPayload(
        jsonEncode({
          'kind': 'countdown',
          'circle_id': '',
          'milestone_id': 'm1',
        }),
      ),
      isNull,
    );
  });

  test('ids are stable and stay in the positive int range Android expects', () {
    expect(CountdownReminder.idFor('m1'), CountdownReminder.idFor('m1'));
    expect(
      CountdownReminder.idFor('m1'),
      isNot(CountdownReminder.idFor('m2')),
    );
    expect(CountdownReminder.idFor('3872bdb3-b973-4cac-885a-11d3be753c80'),
        isNonNegative);
  });

  test('stays quiet once the day itself arrives', () {
    final plan = milestone(date: DateTime(2026, 11, 20));
    final dayBefore = DateTime(2026, 11, 19, 17);

    expect(build(plan, now: dayBefore), isNotNull);
    expect(build(plan, now: DateTime(2026, 11, 20, 9)), isNull);
  });

  test('skips an evening that already passed', () {
    final plan = milestone(date: DateTime(2026, 11, 20));

    expect(build(plan, now: DateTime(2026, 11, 19, 17, 59)), isNotNull);
    expect(build(plan, now: DateTime(2026, 11, 19, 18)), isNull);
    expect(build(plan, now: DateTime(2026, 11, 19, 21)), isNull);
  });
}
