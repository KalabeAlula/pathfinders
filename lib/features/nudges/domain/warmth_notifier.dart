import 'warmth_notification.dart';

/// The system-level surface for warmth that arrives while the app is hidden.
///
/// Kept behind an interface so the controller can be tested without the
/// notification plugin's platform channels.
abstract interface class WarmthNotifier {
  /// Asks for notification permission the first time it is needed. Later
  /// calls are cheap no-ops.
  Future<void> ensurePermission();

  Future<void> show(WarmthNotification notification);
}
