import 'countdown_reminder.dart';

abstract interface class CountdownReminderScheduler {
  Future<void> ensurePermission();

  /// Makes the OS alarm queue match [reminders]: stale alarms are cancelled,
  /// and every reminder is (re)scheduled at its evening time.
  Future<void> sync(List<CountdownReminder> reminders);
}
