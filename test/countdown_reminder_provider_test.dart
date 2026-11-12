import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/domain/circle_summary.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/milestones/application/countdown_reminder_providers.dart';
import 'package:pathfinders/features/milestones/application/milestones_providers.dart';
import 'package:pathfinders/features/milestones/domain/countdown_reminder.dart';
import 'package:pathfinders/features/milestones/domain/countdown_reminder_scheduler.dart';
import 'package:pathfinders/features/milestones/domain/shared_milestone.dart';

class _FakeScheduler implements CountdownReminderScheduler {
  final List<List<CountdownReminder>> syncs = [];
  int permissionRequests = 0;

  @override
  Future<void> ensurePermission() async {
    permissionRequests++;
  }

  @override
  Future<void> sync(List<CountdownReminder> reminders) async {
    syncs.add(List.of(reminders));
  }
}

CircleSummary _circle(String id, String name) {
  return CircleSummary(
    id: id,
    name: name,
    type: GroupType.friends,
    memberCount: 2,
    createdAt: DateTime(2026, 1, 1),
  );
}

SharedMilestone _plan(String id, DateTime date, {String? place}) {
  return SharedMilestone(
    id: id,
    title: 'Plan $id',
    date: date,
    kind: MilestoneKind.trip,
    startsAt: DateTime(date.year, date.month, date.day, 19),
    place: place,
  );
}

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _inDays(int days) => _today.add(Duration(days: days));

DateTime _evening(int daysFromToday) {
  final day = _inDays(daysFromToday);
  return DateTime(day.year, day.month, day.day, 18);
}

void main() {
  late _FakeScheduler scheduler;

  ProviderContainer build(List<CircleSummary> circles, Map<String, List<SharedMilestone>> plans) {
    scheduler = _FakeScheduler();
    final container = ProviderContainer(
      overrides: [
        circlesProvider('u').overrideWith((_) => Stream.value(circles)),
        for (final entry in plans.entries)
          milestonesProvider(
            entry.key,
          ).overrideWith((_) => Stream.value(entry.value)),
        countdownReminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);
    container.listen(countdownRemindersProvider('u'), (_, _) {});
    return container;
  }

  Future<List<CountdownReminder>> settle(ProviderContainer container) async {
    await pumpEventQueue();
    return container.read(countdownRemindersProvider('u'));
  }

  test('queues one evening reminder per upcoming countdown', () async {
    final container = build(
      [_circle('c1', 'Cake Lovers'), _circle('c2', 'Simien Pair')],
      {
        'c1': [_plan('m1', _inDays(2), place: 'Gast Mall')],
        'c2': [_plan('m2', _inDays(3))],
      },
    );
    final reminders = await settle(container);

    expect(reminders, hasLength(2));
    expect(reminders.first.title, 'Plan m1 is tomorrow');
    expect(reminders.first.body, 'Cake Lovers · 7:00 PM · Gast Mall');
    expect(reminders.first.scheduledAt, _evening(1));
    expect(reminders.last.circleId, 'c2');
    expect(scheduler.syncs.last, hasLength(2));
    expect(scheduler.permissionRequests, greaterThanOrEqualTo(1));
  });

  test('leaves today and past countdowns out of the queue', () async {
    final container = build(
      [_circle('c1', 'Cake Lovers')],
      {
        'c1': [
          _plan('today', _inDays(0)),
          _plan('past', _inDays(-4)),
          _plan('soon', _inDays(2)),
        ],
      },
    );
    final reminders = await settle(container);

    expect(reminders.map((reminder) => reminder.milestoneId), ['soon']);
  });

  test('syncs an empty queue and skips the prompt when nothing is coming', () async {
    final container = build(
      [_circle('c1', 'Cake Lovers')],
      {
        'c1': [_plan('today', _inDays(0))],
      },
    );
    await settle(container);

    expect(scheduler.syncs.last, isEmpty);
    expect(scheduler.permissionRequests, 0);
  });

  test('keeps only the soonest twenty countdowns', () async {
    final container = build(
      [_circle('c1', 'Cake Lovers')],
      {
        'c1': [for (var day = 2; day < 23; day++) _plan('m$day', _inDays(day))],
      },
    );
    final reminders = await settle(container);

    expect(reminders, hasLength(20));
    expect(reminders.first.milestoneId, 'm2');
    expect(reminders.last.milestoneId, 'm21');
    expect(reminders.last.scheduledAt, _evening(20));
  });

  test('holds the queue until every circle has answered', () async {
    final plans = StreamController<List<SharedMilestone>>();
    addTearDown(plans.close);
    scheduler = _FakeScheduler();
    final container = ProviderContainer(
      overrides: [
        circlesProvider(
          'u',
        ).overrideWith((_) => Stream.value([_circle('c1', 'Cake Lovers')])),
        milestonesProvider('c1').overrideWith((_) => plans.stream),
        countdownReminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);
    container.listen(countdownRemindersProvider('u'), (_, _) {});

    await pumpEventQueue();
    expect(scheduler.syncs, isEmpty);

    plans.add([_plan('m2', _inDays(2))]);
    await pumpEventQueue();
    expect(scheduler.syncs.last, hasLength(1));
  });
}
