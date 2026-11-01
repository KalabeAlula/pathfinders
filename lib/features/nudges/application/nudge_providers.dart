import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mock_nudge_repository.dart';
import '../domain/nudge.dart';
import '../domain/nudge_repository.dart';

part 'nudge_providers.g.dart';

@Riverpod(keepAlive: true)
NudgeRepository nudgeRepository(Ref ref) => MockNudgeRepository();

/// Holds the nudge currently playing on screen. The overlay clears itself so
/// callers only have to send.
@riverpod
class NudgeController extends _$NudgeController {
  Timer? _clearTimer;

  @override
  NudgePing? build() {
    ref.onDispose(() => _clearTimer?.cancel());
    return null;
  }

  Future<void> sendNudge({
    required String fromUserId,
    required List<String> recipientIds,
    NudgeKind kind = NudgeKind.thinkingOfYou,
  }) async {
    final recipients = recipientIds
        .where((id) => id != fromUserId)
        .toList(growable: false);
    if (recipients.isEmpty) return;

    final ping = await ref.read(nudgeRepositoryProvider).send(
          fromUserId: fromUserId,
          recipientIds: recipients,
          kind: kind,
        );
    if (!ref.mounted) return;

    state = ping;
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 2800), () {
      if (ref.mounted) state = null;
    });
  }
}
