import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../circle/application/circle_providers.dart';
import '../data/local_countdown_reminder_scheduler.dart';
import '../domain/countdown_reminder.dart';
import '../domain/countdown_reminder_scheduler.dart';
import 'milestones_providers.dart';

part 'countdown_reminder_providers.g.dart';

@Riverpod(keepAlive: true)
CountdownReminderScheduler countdownReminderScheduler(Ref ref) =>
    LocalCountdownReminderScheduler(ref.watch(sharedPreferencesProvider));

/// Keeps the OS alarm queue in step with the countdowns this member can see.
///
/// Watched from the circle gate, which stays mounted for the whole signed-in
/// session, so every circle's milestones and every edit reach the scheduler.
@riverpod
List<CountdownReminder> countdownReminders(Ref ref, String userId) {
  final loaded = ref.watch(circlesProvider(userId)).value;
  if (loaded == null) return const [];

  final now = DateTime.now();
  final reminders = <CountdownReminder>[];
  var complete = true;
  for (final circle in loaded) {
    final plans = ref.watch(milestonesProvider(circle.id)).value;
    if (plans == null) {
      // Syncing a partial picture would cancel alarms for circles that simply
      // have not answered yet, so the queue waits for every circle.
      complete = false;
      continue;
    }
    for (final milestone in plans) {
      final reminder = CountdownReminder.forMilestone(
        milestone: milestone,
        circleId: circle.id,
        circleName: circle.name,
        now: now,
      );
      if (reminder != null) reminders.add(reminder);
    }
  }
  reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  // iOS keeps at most 64 pending notifications per app; the soonest few cover
  // any realistic circle without brushing that ceiling.
  if (reminders.length > 20) reminders.removeRange(20, reminders.length);
  if (!complete) return reminders;

  final scheduler = ref.watch(countdownReminderSchedulerProvider);
  if (reminders.isNotEmpty) unawaited(scheduler.ensurePermission());
  unawaited(scheduler.sync(reminders));
  return reminders;
}
