import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/clock_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../chat/application/chat_providers.dart';
import '../../circle/application/circle_providers.dart';
import '../../memories/application/memories_providers.dart';
import '../../milestones/application/milestones_providers.dart';
import '../../navigation/application/arrival_controller.dart';
import '../domain/pet_mood.dart';

part 'pet_mood_providers.g.dart';

// ---------------------------------------------------------------------------
// Ephemeral "loved" state — fires for [_lovedDuration] after any care action.
// ---------------------------------------------------------------------------

const Duration _lovedDuration = Duration(seconds: 5);

/// Fires [true] for [_lovedDuration] after Feed / Clean / Play, then resets.
@Riverpod(keepAlive: false)
class LovedState extends _$LovedState {
  Timer? _timer;

  @override
  bool build(String circleId) {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  /// Call this right after a successful care action to trigger the loved mood.
  void trigger() {
    _timer?.cancel();
    state = true;
    _timer = Timer(_lovedDuration, () {
      if (ref.mounted) state = false;
    });
  }
}

// ---------------------------------------------------------------------------
// Main mood provider
// ---------------------------------------------------------------------------

/// The companion's sticker state for [circleId].
///
/// Watches are narrowed via `.select` so distance ticks, member telemetry, and
/// unrelated snapshot fields don't rebuild the sticker.
@riverpod
PetMood petMood(Ref ref, String circleId) {
  final userId = ref.watch(authSessionProvider).value?.userId;
  if (userId == null) return PetMood.idle;

  // Ephemeral loved state takes top priority.
  final loved = ref.watch(lovedStateProvider(circleId));
  if (loved) return PetMood.loved;

  // Trip state (celebrating / traveling).
  final trip = ref.watch(
    arrivalControllerProvider(circleId).select(
      (state) => (
        hasDestination: state.destination != null,
        arrived: state.arrived,
        everyoneArrived: state.everyoneArrived,
      ),
    ),
  );

  // Energy + last-care timestamp from the circle snapshot.
  final rest = ref.watch(
    circleSnapshotProvider(userId).select((snapshot) {
      final circle = snapshot.value?.circle;
      if (circle == null) return null;
      return (
        energy: circle.petEnergy,
        updatedAt: circle.petUpdatedAt ?? circle.createdAt,
      );
    }),
  );

  // Online member count from snapshot (already computed field).
  final onlineCount = ref.watch(
    circleSnapshotProvider(userId)
        .select((snapshot) => snapshot.value?.onlineCount ?? 0),
  );

  final now = ref.watch(appClockProvider).value ?? DateTime.now();

  // Upcoming milestone within 48 h.
  final twoHoursAgo = now.subtract(const Duration(hours: 2));
  final in48h = now.add(const Duration(hours: 48));
  final countdownSoon =
      ref
          .watch(milestonesProvider(circleId))
          .value
          ?.any((m) => m.sortKey.isAfter(now) && m.sortKey.isBefore(in48h)) ??
      false;

  // Recent chat activity (last 2 h, excluding own messages).
  final recentChatCount =
      ref
          .watch(circleMessagesProvider(circleId))
          .value
          ?.where(
            (m) => m.senderId != userId && m.createdAt.isAfter(twoHoursAgo),
          )
          .length ??
      0;

  // Any memory posted by someone else in the last 2 h.
  final recentMemory =
      ref
          .watch(recentMemoriesProvider(circleId))
          .value
          ?.any(
            (m) => m.authorId != userId && m.createdAt.isAfter(twoHoursAgo),
          ) ??
      false;

  return derivePetMood(
    hasDestination: trip.hasDestination,
    arrived: trip.arrived,
    everyoneArrived: trip.everyoneArrived,
    now: now,
    energy: rest?.energy ?? 100,
    lastActivityAt: rest?.updatedAt,
    onlineCount: onlineCount,
    countdownSoon: countdownSoon,
    recentChatCount: recentChatCount,
    recentMemory: recentMemory,
  );
}
