import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/notification_plugin.dart';
import '../domain/warmth_notification.dart';
import '../domain/warmth_notifier.dart';

/// Renders warmth with the system notification service.
///
/// Only the mobile platforms have a notification shade; elsewhere the in-app
/// banner stays the only surface.
class LocalWarmthNotifier implements WarmthNotifier {
  LocalWarmthNotifier(
    this._preferences, {
    NotificationPlugin? notifications,
  }) : _notifications = notifications ?? NotificationPlugin.instance;

  final SharedPreferences _preferences;
  final NotificationPlugin _notifications;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> ensurePermission() =>
      _notifications.ensurePermission(_preferences);

  @override
  Future<void> show(WarmthNotification notification) async {
    if (!_isMobile) return;
    await _notifications.ensureInitialized();
    await _notifications.plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      payload: notification.payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationPlugin.warmthChannelId,
          NotificationPlugin.warmthChannelName,
          channelDescription: NotificationPlugin.warmthChannelDescription,
          icon: NotificationPlugin.icon,
          importance: Importance.high,
          priority: Priority.high,
          color: NotificationPlugin.brandColor,
          category: AndroidNotificationCategory.message,
        ),
        iOS: DarwinNotificationDetails(
          presentBanner: true,
          presentList: true,
          presentSound: true,
          threadIdentifier: 'warmth',
        ),
      ),
    );
  }
}
