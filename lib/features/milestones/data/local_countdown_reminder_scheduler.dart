import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/notifications/notification_plugin.dart';
import '../domain/countdown_reminder.dart';
import '../domain/countdown_reminder_scheduler.dart';

/// Hands countdown reminders to the OS alarm queue.
///
/// The plugin persists scheduled alarms itself, so a reminder still fires
/// after the app is killed; the boot receiver registered in the manifest puts
/// them back after a restart.
class LocalCountdownReminderScheduler implements CountdownReminderScheduler {
  LocalCountdownReminderScheduler(
    this._preferences, {
    NotificationPlugin? notifications,
  }) : _notifications = notifications ?? NotificationPlugin.instance;

  /// Alarms this install has queued, as `id:millisecondsSinceEpoch`, so ones
  /// the circle removed or moved can be cancelled and refreshed. The plugin
  /// appends rather than replaces alarms re-scheduled under the same id.
  static const _slotsKey = 'countdown_reminder_slots';

  final SharedPreferences _preferences;
  final NotificationPlugin _notifications;

  bool _timeZoneReady = false;
  Future<void> _tail = Future<void>.value();

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> ensurePermission() =>
      _notifications.ensurePermission(_preferences);

  @override
  Future<void> sync(List<CountdownReminder> reminders) {
    final snapshot = List<CountdownReminder>.of(reminders);
    final run = _tail.then((_) => _sync(snapshot));
    _tail = run.then((_) {}, onError: (Object _, StackTrace _) {});
    return run;
  }

  Future<void> _sync(List<CountdownReminder> reminders) async {
    if (!_isMobile) return;
    await _notifications.ensureInitialized();
    await _prepareTimeZone();

    final stored = _preferences.getStringList(_slotsKey);
    if (stored == null) {
      // First sync on this install: a build that did not record its slots may
      // have left alarms behind, and those cannot be identified any more.
      await _notifications.plugin.cancelAllPendingNotifications();
    }
    final queued = _parseSlots(stored ?? const []);
    final current = {
      for (final reminder in reminders)
        reminder.id: reminder.scheduledAt.millisecondsSinceEpoch,
    };

    for (final id in queued.keys) {
      if (current.containsKey(id)) continue;
      await _notifications.plugin.cancel(id: id);
    }

    for (final reminder in reminders) {
      if (queued[reminder.id] == current[reminder.id]) continue;
      await _notifications.plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        payload: reminder.payload,
        scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
        // Inexact keeps the reminder out of the exact-alarm permission, and an
        // evening heads-up does not need minute precision.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationPlugin.countdownChannelId,
            NotificationPlugin.countdownChannelName,
            channelDescription:
                NotificationPlugin.countdownChannelDescription,
            icon: NotificationPlugin.icon,
            importance: Importance.high,
            priority: Priority.high,
            color: NotificationPlugin.brandColor,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentBanner: true,
            presentList: true,
            presentSound: true,
            threadIdentifier: 'countdowns',
          ),
        ),
      );
    }

    await _preferences.setStringList(
      _slotsKey,
      [for (final entry in current.entries) '${entry.key}:${entry.value}'],
    );
  }

  Map<int, int> _parseSlots(List<String> entries) {
    final slots = <int, int>{};
    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final id = int.tryParse(parts[0]);
      final at = int.tryParse(parts[1]);
      if (id != null && at != null) slots[id] = at;
    }
    return slots;
  }

  Future<void> _prepareTimeZone() async {
    if (_timeZoneReady) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Exception {
      // An unknown zone name must not stop scheduling; tz.local stays UTC.
    }
    _timeZoneReady = true;
  }
}
