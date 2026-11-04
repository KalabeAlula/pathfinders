import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/warmth_notification.dart';
import '../domain/warmth_notifier.dart';

/// Renders warmth with the system notification service.
///
/// Only the mobile platforms have a notification shade; elsewhere the in-app
/// banner stays the only surface.
class LocalWarmthNotifier implements WarmthNotifier {
  LocalWarmthNotifier(
    this._preferences, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _permissionAskedKey = 'warmth_notification_permission_asked';
  static const _channelId = 'pathfinders_warmth';
  static const _channelName = 'Warmth';
  static const _channelDescription =
      'Kisses, hugs, and check-ins from your circle.';
  static const _icon = 'ic_stat_pathfinders';
  static const _brandColor = Color(0xFFB86B4F);

  final SharedPreferences _preferences;
  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> ensurePermission() async {
    if (!_isMobile) return;
    if (_preferences.getBool(_permissionAskedKey) ?? false) return;
    await _ensureReady();
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    // A denial is recorded too: the system prompt only makes sense once, and
    // a member can still enable the channel from Settings later.
    await _preferences.setBool(_permissionAskedKey, true);
  }

  @override
  Future<void> show(WarmthNotification notification) async {
    if (!_isMobile) return;
    await _ensureReady();
    await _plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      payload: notification.payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          icon: _icon,
          importance: Importance.high,
          priority: Priority.high,
          color: _brandColor,
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

  Future<void> _ensureReady() => _ready ??= _initialize();

  Future<void> _initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_icon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
  }
}
