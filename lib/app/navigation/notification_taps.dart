import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/notifications/notification_plugin.dart';
import '../../features/chat/application/chat_notification_providers.dart';
import '../../features/milestones/application/countdown_reminder_providers.dart';

part 'notification_taps.g.dart';

/// Routes notification taps to the feature that owns each payload.
///
/// `NotificationPlugin` reports the cold-start payload to a single reader, so
/// one dispatcher reads it and hands it to every router. It lives above the
/// signed-in shell so a tap is not lost while the session gate is resolving.
@Riverpod(keepAlive: true)
NotificationTapDispatcher notificationTapDispatcher(Ref ref) {
  final dispatcher = NotificationTapDispatcher([
    ChatNotificationRouter(
      ref.read(chatNotificationTargetProvider.notifier),
      ref.read(chatNotificationsProvider),
    ).handlePayload,
    CountdownReminderRouter(
      ref.read(countdownReminderTargetProvider.notifier),
    ).handlePayload,
  ]);
  final subscription = NotificationPlugin.instance.taps.listen(
    dispatcher.handlePayload,
  );
  ref.onDispose(subscription.cancel);

  unawaited(
    NotificationPlugin.instance.takeLaunchPayload().then((payload) {
      if (payload != null) dispatcher.handlePayload(payload);
    }),
  );
  return dispatcher;
}

class NotificationTapDispatcher {
  NotificationTapDispatcher(this._handlers);

  final List<void Function(String payload)> _handlers;

  void handlePayload(String payload) {
    for (final handle in _handlers) {
      handle(payload);
    }
  }
}
