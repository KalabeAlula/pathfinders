import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/notification_plugin.dart';
import '../domain/chat_notification.dart';
import '../domain/chat_notifier.dart';

/// Renders chat messages with the system notification service.
///
/// Each circle owns a notification group: one child per message plus a silent
/// summary, so a busy group stacks in the shade instead of spamming it.
class LocalChatNotifier implements ChatNotifier {
  LocalChatNotifier(
    this._preferences, {
    NotificationPlugin? notifications,
  }) : _notifications = notifications ?? NotificationPlugin.instance;

  /// Keeps the summary's inbox lines short and bounded.
  static const _maxGrouped = 8;

  final SharedPreferences _preferences;
  final NotificationPlugin _notifications;
  final Map<String, List<ChatNotification>> _groups = {};

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> ensurePermission() =>
      _notifications.ensurePermission(_preferences);

  @override
  Future<void> show(
    ChatNotification notification, {
    required String circleName,
  }) async {
    if (!_isSupported) return;
    await _notifications.ensureInitialized();

    final group = _groups.putIfAbsent(notification.circleId, () => []);
    group
      ..removeWhere((entry) => entry.id == notification.id)
      ..add(notification);
    if (group.length > _maxGrouped) {
      group.removeRange(0, group.length - _maxGrouped);
    }

    final groupKey = ChatNotification.groupKeyFor(notification.circleId);
    await _notifications.plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      payload: notification.payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationPlugin.chatChannelId,
          NotificationPlugin.chatChannelName,
          channelDescription: NotificationPlugin.chatChannelDescription,
          icon: NotificationPlugin.icon,
          importance: Importance.max,
          priority: Priority.high,
          color: NotificationPlugin.brandColor,
          enableVibration: true,
          groupKey: groupKey,
          category: AndroidNotificationCategory.message,
          styleInformation: BigTextStyleInformation(notification.body),
        ),
        iOS: DarwinNotificationDetails(
          presentBanner: true,
          presentList: true,
          presentSound: true,
          threadIdentifier: groupKey,
        ),
      ),
    );

    final count = group.length;
    await _notifications.plugin.show(
      id: ChatNotification.summaryIdFor(notification.circleId),
      title: circleName,
      body: count == 1 ? notification.body : '$count new messages',
      payload: notification.payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationPlugin.chatChannelId,
          NotificationPlugin.chatChannelName,
          channelDescription: NotificationPlugin.chatChannelDescription,
          icon: NotificationPlugin.icon,
          importance: Importance.max,
          priority: Priority.high,
          color: NotificationPlugin.brandColor,
          groupKey: groupKey,
          setAsGroupSummary: true,
          groupAlertBehavior: GroupAlertBehavior.children,
          onlyAlertOnce: true,
          styleInformation: InboxStyleInformation(
            [for (final entry in group) '${entry.senderName}: ${entry.body}'],
            contentTitle: circleName,
            summaryText: '$count new message${count == 1 ? '' : 's'}',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentBanner: false,
          presentList: false,
          presentSound: false,
          threadIdentifier: groupKey,
        ),
      ),
    );
  }

  @override
  Future<void> clearCircle(String circleId) async {
    if (!_isSupported) return;
    await _notifications.ensureInitialized();

    final group = _groups.remove(circleId) ?? const <ChatNotification>[];
    for (final entry in group) {
      await _notifications.plugin.cancel(id: entry.id);
    }
    await _notifications.plugin.cancel(
      id: ChatNotification.summaryIdFor(circleId),
    );

    if (!Platform.isAndroid) return;
    try {
      // Tracked ids cover this process; the sweep also clears entries posted
      // before a restart.
      final active = await _notifications.plugin.getActiveNotifications();
      final groupKey = ChatNotification.groupKeyFor(circleId);
      for (final notification in active) {
        final id = notification.id;
        if (id != null && notification.groupKey == groupKey) {
          await _notifications.plugin.cancel(id: id);
        }
      }
    } on Exception {
      // The tracked ids above are enough; the sweep is best effort.
    }
  }
}
