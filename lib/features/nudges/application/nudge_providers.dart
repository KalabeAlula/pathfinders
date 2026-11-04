import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/app_visibility.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/local_warmth_notifier.dart';
import '../data/supabase_nudge_repository.dart';
import '../domain/nudge.dart';
import '../domain/nudge_repository.dart';
import '../domain/warmth_notification.dart';
import '../domain/warmth_notifier.dart';

part 'nudge_providers.g.dart';

@Riverpod(keepAlive: true)
NudgeRepository nudgeRepository(Ref ref, String circleId) =>
    SupabaseNudgeRepository(
      ref.watch(supabaseClientProvider),
      circleId: circleId,
    );

@Riverpod(keepAlive: true)
WarmthNotifier warmthNotifications(Ref ref) =>
    LocalWarmthNotifier(ref.watch(sharedPreferencesProvider));

/// Shows the most recent warmth action, then clears itself so the banner
/// disappears without the caller managing a timer.
///
/// While the app is backgrounded the same ping is also handed to the system
/// notification service; in the foreground the in-app banner is the only cue.
@riverpod
class NudgeController extends _$NudgeController {
  Timer? _clearTimer;
  StreamSubscription<NudgePing>? _incoming;

  @override
  NudgePing? build(String circleId, String userId) {
    ref.onDispose(() {
      _clearTimer?.cancel();
      _incoming?.cancel();
    });
    final notifier = ref.watch(warmthNotificationsProvider);
    final visibility = ref.watch(appVisibilityProvider);
    unawaited(notifier.ensurePermission());
    _incoming = ref
        .watch(nudgeRepositoryProvider(circleId))
        .watchIncoming(userId)
        .listen((ping) {
          if (ping.targetId != userId) return;
          _reveal(ping);
          if (!visibility.isForeground) {
            unawaited(notifier.show(WarmthNotification.fromPing(ping)));
          }
        });
    return null;
  }

  Future<void> send({
    required String senderId,
    required String senderName,
    required String targetId,
    required String targetName,
    required NudgeWarmth warmth,
  }) async {
    final message = warmth.messageFor(senderName);
    await ref
        .read(nudgeRepositoryProvider(circleId))
        .send(
          senderId: senderId,
          targetId: targetId,
          warmth: warmth,
          message: message,
        );
    if (!ref.mounted) return;

    final sentAt = DateTime.now();
    _reveal(
      NudgePing(
        id: 'local-${sentAt.microsecondsSinceEpoch}',
        circleId: circleId,
        fromUserId: senderId,
        fromName: senderName,
        targetId: targetId,
        targetName: targetName,
        warmth: warmth,
        message: message,
        sentAt: sentAt,
      ),
    );
  }

  void _reveal(NudgePing ping) {
    state = ping;
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 3600), () {
      if (ref.mounted) state = null;
    });
  }
}
