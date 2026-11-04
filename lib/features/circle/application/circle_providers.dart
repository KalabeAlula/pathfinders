import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../chat/application/chat_providers.dart';
import '../../memories/application/memories_providers.dart';
import '../../milestones/application/milestones_providers.dart';
import '../data/active_circle_store.dart';
import '../data/supabase_circle_repository.dart';
import '../domain/circle_repository.dart';
import '../domain/circle_snapshot.dart';
import '../domain/circle_summary.dart';

part 'circle_providers.g.dart';

@Riverpod(keepAlive: true)
CircleRepository circleRepository(Ref ref, String userId) =>
    SupabaseCircleRepository(ref.watch(supabaseClientProvider), userId: userId);

@Riverpod(keepAlive: true)
ActiveCircleStore activeCircleStore(Ref ref) =>
    ActiveCircleStore(ref.watch(sharedPreferencesProvider));

/// Every group the signed-in member belongs to, oldest membership first.
@riverpod
Stream<List<CircleSummary>> circles(Ref ref, String userId) =>
    ref.watch(circleRepositoryProvider(userId)).watchCircles();

/// The circle whose membership this device just lost, so the gate can explain
/// why the screen changed. Cleared as soon as it is shown.
@Riverpod(keepAlive: true)
class CircleMembershipNotice extends _$CircleMembershipNotice {
  @override
  String? build() => null;

  void show(String circleName) => state = circleName;

  void clear() => state = null;
}

/// The group currently on screen. A saved id wins only while it still matches
/// a membership; otherwise the oldest group is used so a removed group cannot
/// leave the app pointing at nothing.
@Riverpod(keepAlive: true)
class ActiveCircleController extends _$ActiveCircleController {
  final Set<String> _forgotten = {};
  List<CircleSummary>? _knownMemberships;

  @override
  String? build(String userId) {
    final saved = ref.watch(activeCircleStoreProvider).read(userId);
    final circles = ref.watch(circlesProvider(userId));
    final memberships = circles.value;

    // A membership can disappear without this device asking: the creator can
    // remove the member or delete the circle. The list is the authority, so a
    // circle that drops out is cleaned up like a voluntary leave. The live
    // state is captured because this build has already moved on to the
    // fallback, and a voluntary leave sets it directly.
    final known = _knownMemberships;
    if (memberships != null) {
      _knownMemberships = memberships;
      if (known != null) {
        final currentIds = {for (final circle in memberships) circle.id};
        final departed = [
          for (final circle in known)
            if (!currentIds.contains(circle.id)) circle,
        ];
        if (departed.isNotEmpty) {
          final activeBefore = state;
          unawaited(
            Future.microtask(
              () => _handleDepartedCircles(departed, memberships, activeBefore),
            ),
          );
        }
      }
    }

    final list = memberships ?? const <CircleSummary>[];
    final firstLook = known == null;
    final result = switch (list) {
      [] => circles.isLoading ? saved : null,
      _ when saved == null => list.first.id,
      _ when list.any((circle) => circle.id == saved) => saved,
      _ when circles.isLoading => saved,
      _ => list.first.id,
    };

    if (firstLook &&
        saved != null &&
        !circles.isLoading &&
        !list.any((circle) => circle.id == saved)) {
      // Removed while the app was closed: there is no earlier list to diff,
      // so clean up the saved membership on its own.
      if (result == null) {
        unawaited(_forgetSavedMembership(saved));
      } else {
        unawaited(_adoptMembership(saved, result));
      }
    }

    return result;
  }

  Future<void> select(String circleId) async {
    await ref.read(activeCircleStoreProvider).write(userId, circleId);
    if (!ref.mounted) return;
    state = circleId;
  }

  Future<void> leaveCircle(String circleId) async {
    await ref
        .read(circleRepositoryProvider(userId))
        .leaveCircle(circleId: circleId);
    await _forgetMembership(circleId);
  }

  Future<void> deleteCircle(String circleId) async {
    await ref
        .read(circleRepositoryProvider(userId))
        .deleteCircle(circleId: circleId);
    await _forgetMembership(circleId);
  }

  Future<void> renameCircle(String circleId, String name) async {
    await ref
        .read(circleRepositoryProvider(userId))
        .renameCircle(circleId: circleId, name: name);
    // The switcher names groups from this list; realtime also refreshes it,
    // but invalidating makes the new name immediate.
    ref.invalidate(circlesProvider(userId));
  }

  Future<String> rotateInviteCode(String circleId) {
    return ref
        .read(circleRepositoryProvider(userId))
        .rotateInviteCode(circleId: circleId);
  }

  Future<void> removeMember(String circleId, String memberId) {
    return ref
        .read(circleRepositoryProvider(userId))
        .removeMember(circleId: circleId, memberId: memberId);
  }

  Future<void> transferOwnership(String circleId, String newOwnerId) {
    return ref
        .read(circleRepositoryProvider(userId))
        .transferOwnership(circleId: circleId, newOwnerId: newOwnerId);
  }

  /// Clears this device's cached view of the circle and moves the active id
  /// when the circle that just vanished was the one on screen.
  Future<void> _forgetMembership(String circleId) async {
    await _clearMembershipCaches(circleId);

    final remaining = <CircleSummary>[
      for (final circle
          in ref.read(circlesProvider(userId)).value ?? const <CircleSummary>[])
        if (circle.id != circleId) circle,
    ];

    if (state == circleId) {
      if (remaining.isEmpty) {
        await ref.read(activeCircleStoreProvider).clear(userId);
        if (!ref.mounted) return;
        state = null;
      } else {
        await ref
            .read(activeCircleStoreProvider)
            .write(userId, remaining.first.id);
        if (!ref.mounted) return;
        state = remaining.first.id;
      }
    }

    // Realtime normally refreshes the list; this makes the switch immediate.
    ref.invalidate(circlesProvider(userId));
  }

  Future<void> _handleDepartedCircles(
    List<CircleSummary> departed,
    List<CircleSummary> remainingSource,
    String? activeBefore,
  ) async {
    final departedIds = {for (final circle in departed) circle.id};
    final savedBefore = ref.read(activeCircleStoreProvider).read(userId);
    final watched = [
      for (final id in [activeBefore, savedBefore])
        if (id != null && departedIds.contains(id)) id,
    ];

    if (watched.isNotEmpty) {
      final lost = departed.firstWhere((circle) => circle.id == watched.first);
      ref.read(circleMembershipNoticeProvider.notifier).show(lost.name);
    }

    await Future.wait([
      for (final circleId in departedIds) _clearMembershipCaches(circleId),
    ]);
    if (!ref.mounted) return;

    if (watched.isEmpty) return;

    final remaining = <CircleSummary>[
      for (final circle in remainingSource)
        if (!departedIds.contains(circle.id)) circle,
    ];

    if (remaining.isEmpty) {
      await ref.read(activeCircleStoreProvider).clear(userId);
      if (!ref.mounted) return;
      state = null;
    } else {
      await ref
          .read(activeCircleStoreProvider)
          .write(userId, remaining.first.id);
      if (!ref.mounted) return;
      state = remaining.first.id;
    }
  }

  Future<void> _forgetSavedMembership(String circleId) async {
    if (!_forgotten.add(circleId)) return;
    await _clearMembershipCaches(circleId);
    if (!ref.mounted) return;
    final store = ref.read(activeCircleStoreProvider);
    if (store.read(userId) == circleId) await store.clear(userId);
  }

  Future<void> _adoptMembership(String savedId, String activeId) async {
    if (!_forgotten.add(savedId)) return;
    await _clearMembershipCaches(savedId);
    if (!ref.mounted) return;
    await ref.read(activeCircleStoreProvider).write(userId, activeId);
  }

  Future<void> _clearMembershipCaches(String circleId) {
    return Future.wait([
      ref.read(memoriesCacheProvider(circleId)).clear(),
      ref.read(milestonesCacheProvider(circleId)).clear(),
      ref.read(chatSeenStoreProvider).clear(circleId),
    ]);
  }
}

@riverpod
CircleSummary? activeCircle(Ref ref, String userId) {
  final activeId = ref.watch(activeCircleControllerProvider(userId));
  final memberships =
      ref.watch(circlesProvider(userId)).value ?? const <CircleSummary>[];
  for (final circle in memberships) {
    if (circle.id == activeId) return circle;
  }
  return null;
}

/// Live data for the active group. Changing the active id rebuilds this
/// stream, which cancels the previous repository subscription (and its
/// realtime channel) before the next one starts.
@riverpod
Stream<CircleSnapshot?> circleSnapshot(Ref ref, String userId) {
  final circleId = ref.watch(activeCircleControllerProvider(userId));
  if (circleId == null) return Stream<CircleSnapshot?>.value(null);
  return ref.watch(circleRepositoryProvider(userId)).watchCircle(circleId);
}
