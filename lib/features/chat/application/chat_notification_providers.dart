import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/app_visibility.dart';
import '../../../core/notifications/notification_plugin.dart';
import '../../../core/storage/storage_providers.dart';
import '../../circle/application/circle_providers.dart';
import '../../circle/domain/circle_summary.dart';
import '../data/local_chat_notifier.dart';
import '../domain/chat_message.dart';
import '../domain/chat_notification.dart';
import '../domain/chat_notifier.dart';
import 'chat_providers.dart';

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

/// Watches every circle's thread and posts a system notification when a
/// message arrives while the app is off screen.
///
/// The subscriptions are created here, at the signed-in shell, and live for
/// the whole session: that is what keeps the realtime channels receiving
/// while the app is minimized.
@Riverpod(keepAlive: true)
ChatNotificationWatcher chatNotificationWatcher(Ref ref, String userId) {
  final watcher = ChatNotificationWatcher(
    ref,
    userId: userId,
    notifier: ref.watch(chatNotificationsProvider),
    visibility: ref.read(appVisibilityProvider),
  );
  final circles =
      ref.watch(circlesProvider(userId)).value ?? const <CircleSummary>[];
  watcher.watch(circles);
  return watcher;
}

class ChatNotificationWatcher {
  ChatNotificationWatcher(
    this._ref, {
    required this.userId,
    required this.notifier,
    required this.visibility,
  });

  final Ref _ref;
  final String userId;
  final ChatNotifier notifier;
  final AppVisibility visibility;
  final Map<String, Set<String>> _known = {};

  void watch(List<CircleSummary> circles) {
    unawaited(notifier.ensurePermission());
    for (final circle in circles) {
      _ref.listen<AsyncValue<List<ChatMessage>>>(
        circleMessagesProvider(circle.id),
        (previous, next) => _onMessages(circle, previous, next),
      );
    }
  }

  void _onMessages(
    CircleSummary circle,
    AsyncValue<List<ChatMessage>>? previous,
    AsyncValue<List<ChatMessage>> next,
  ) {
    final messages = next.value;
    if (messages == null) return;

    final known = _known.putIfAbsent(
      circle.id,
      () => {
        for (final message in previous?.value ?? const <ChatMessage>[])
          message.id,
      },
    );

    // The first snapshot is history, not something that just happened.
    if (previous == null || !previous.hasValue) {
      known.addAll(messages.map((message) => message.id));
      return;
    }

    final fresh = [
      for (final message in messages)
        if (!known.contains(message.id)) message,
    ];
    known.addAll(messages.map((message) => message.id));
    if (fresh.isEmpty || visibility.isForeground) return;

    unawaited(() async {
      for (final message in fresh) {
        if (message.senderId == userId || message.isDestinationUpdate) continue;
        await notifier.show(
          ChatNotification.fromMessage(
            message: message,
            circleId: circle.id,
            circleName: circle.name,
          ),
          circleName: circle.name,
        );
      }
    }());
  }
}
