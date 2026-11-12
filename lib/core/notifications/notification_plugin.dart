import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the app's single local notifications plugin.
///
/// `FlutterLocalNotificationsPlugin` is a process-wide singleton and every
/// `initialize` call replaces the tap callback, so warmth and chat share this
/// bootstrap instead of initialising the plugin themselves.
class NotificationPlugin {
  NotificationPlugin._();

  static final NotificationPlugin instance = NotificationPlugin._();

  static const icon = 'ic_stat_pathfinders';
  static const brandColor = Color(0xFFB86B4F);

  static const warmthChannelId = 'pathfinders_warmth';
  static const warmthChannelName = 'Warmth';
  static const warmthChannelDescription =
      'Kisses, hugs, and check-ins from your circle.';

  static const chatChannelId = 'pathfinders_chat_channel';
  static const chatChannelName = 'Crew chat';
  static const chatChannelDescription = 'Messages from your circles.';

  static const countdownChannelId = 'pathfinders_countdowns';
  static const countdownChannelName = 'Countdown reminders';
  static const countdownChannelDescription =
      'An evening heads-up before a countdown your circle planned.';

  static const _permissionAskedKey = 'notification_permission_asked';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _taps = StreamController<String>.broadcast();

  Future<void>? _ready;
  bool _launchPayloadRead = false;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Payloads from notifications the member taps while the app is running.
  Stream<String> get taps => _taps.stream;

  Future<void> ensureInitialized() => _ready ??= _initialize();

  /// The payload that cold-started the app, read at most once.
  Future<String?> takeLaunchPayload() async {
    if (!isSupported || _launchPayloadRead) return null;
    _launchPayloadRead = true;
    await ensureInitialized();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  /// Asks for notification permission once per install.
  ///
  /// The OS is the authority: when notifications are already enabled the
  /// prompt is skipped even if this build has not recorded a request.
  Future<void> ensurePermission(SharedPreferences preferences) async {
    if (!isSupported) return;
    if (preferences.getBool(_permissionAskedKey) ?? false) return;
    await ensureInitialized();

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (await android?.areNotificationsEnabled() == false) {
        await android?.requestNotificationsPermission();
      }
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // A denial is recorded too: the system prompt only makes sense once, and
    // a member can still enable the channel from Settings later.
    await preferences.setBool(_permissionAskedKey, true);
  }

  Future<void> _initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(icon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        warmthChannelId,
        warmthChannelName,
        description: warmthChannelDescription,
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        chatChannelId,
        chatChannelName,
        description: chatChannelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        countdownChannelId,
        countdownChannelName,
        description: countdownChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }
}
