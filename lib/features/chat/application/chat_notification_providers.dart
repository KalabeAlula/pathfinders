import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/notifications/notification_plugin.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/local_chat_notifier.dart';
import '../domain/chat_notification.dart';
import '../domain/chat_notifier.dart';

part 'chat_notification_providers.g.dart';

@Riverpod(keepAlive: true)
ChatNotifier chatNotifications(Ref ref) =>
    LocalChatNotifier(ref.watch(sharedPreferencesProvider));

/// The circle a chat notification tap asked to open. The shell consumes it
/// once, so the request survives the frame that switches both tab and circle.
@Riverpod(keepAlive: true)
class ChatNotificationTarget extends _$ChatNotificationTarget {
  @override
  String? build() => null;

  void open(String circleId) => state = circleId;

  void clear() => state = null;
}

/// Turns notification taps into a pending chat target.
///
/// Lives above the signed-in shell so a cold-start tap is not lost while the
/// session gate is still resolving.
@Riverpod(keepAlive: true)
ChatNotificationRouter chatNotificationRouter(Ref ref) {
  final router = ChatNotificationRouter(
    ref.read(chatNotificationTargetProvider.notifier),
    ref.read(chatNotificationsProvider),
  );
  final subscription = NotificationPlugin.instance.taps.listen(
    router.handlePayload,
  );
  ref.onDispose(subscription.cancel);

  unawaited(
    NotificationPlugin.instance.takeLaunchPayload().then((payload) {
      if (payload != null) router.handlePayload(payload);
    }),
  );
  return router;
}

class ChatNotificationRouter {
  ChatNotificationRouter(this._target, this._notifier);

  final ChatNotificationTarget _target;
  final ChatNotifier _notifier;

  void handlePayload(String payload) {
    final circleId = chatCircleFromPayload(payload);
    if (circleId == null) return;
    _target.open(circleId);
    unawaited(_notifier.clearCircle(circleId));
  }
}
