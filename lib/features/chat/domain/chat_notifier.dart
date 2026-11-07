import 'chat_notification.dart';

/// The system-level surface for chat messages that arrive while the app is
/// hidden. Behind an interface so the watcher can be tested without the
/// notification plugin's platform channels.
abstract interface class ChatNotifier {
  /// Asks for notification permission the first time it is needed. Later
  /// calls are cheap no-ops.
  Future<void> ensurePermission();

  /// Posts [notification] and refreshes the circle's silent group summary.
  Future<void> show(
    ChatNotification notification, {
    required String circleName,
  });

  /// Removes every notification belonging to [circleId], e.g. once its thread
  /// is on screen.
  Future<void> clearCircle(String circleId);
}
