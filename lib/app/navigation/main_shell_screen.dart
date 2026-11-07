import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/push_token_registration.dart';
import '../../features/chat/application/chat_notification_providers.dart';
import '../../features/chat/application/chat_providers.dart';
import '../../features/chat/presentation/chat_tab.dart';
import '../../features/circle/application/circle_providers.dart';
import '../../features/circle/domain/circle_member.dart';
import '../../features/circle/domain/circle_snapshot.dart';
import '../../features/circle/presentation/circle_tab.dart';
import '../../features/circle/presentation/widgets/member_detail_sheet.dart';
import '../../features/location/application/telemetry_providers.dart';
import '../../features/location/domain/geo_point.dart';
import '../../features/memories/application/memories_providers.dart';
import '../../features/memories/presentation/memories_tab.dart';
import '../../features/navigation/application/map_focus_providers.dart';
import '../../features/navigation/application/navigation_providers.dart';
import '../../features/navigation/presentation/map_tab.dart';
import '../../features/nudges/application/nudge_providers.dart';
import '../../features/nudges/presentation/warmth_actions.dart';
import '../../features/nudges/presentation/widgets/warmth_banner.dart';
import '../../features/profile/presentation/profile_tab.dart';
import 'active_tab.dart';
import 'main_shell_scaffold.dart';

/// The signed-in experience: five persistent tabs over one navigation bar.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({
    super.key,
    required this.snapshot,
    required this.currentUserId,
  });

  final CircleSnapshot snapshot;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = snapshot.circle;
    final circleId = circle.id;
    final tab = ref.watch(activeTabControllerProvider);
    final unreadChats = ref.watch(
      chatUnreadCountProvider((circleId: circleId, userId: currentUserId)),
    );
    final newMemories = ref.watch(
      memoriesUnreadCountProvider((circleId: circleId, userId: currentUserId)),
    );
    final activeNudge = ref.watch(
      nudgeControllerProvider(circleId, currentUserId),
    );
    final tripActive = ref.watch(
      navigationControllerProvider(circleId).select((state) => state.isActive),
    );

    // Opening the gallery clears its badge, and moments that land while the
    // member is already watching the gallery are marked seen as they arrive.
    if (tab == AppTab.memories && newMemories > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(memoriesSeenControllerProvider(circleId).notifier)
            .markSeen();
      });
    }

    // The shell stays mounted for the whole signed-in session, so watching the
    // heartbeat here keeps sharing alive across every tab.
    ref.listen(telemetryControllerProvider(currentUserId), (_, _) {});
    // Same for chat notifications: every circle's realtime thread is watched
    // for the whole session so messages keep arriving while the app is away.
    ref.listen(chatNotificationWatcherProvider(currentUserId), (_, _) {});
    // Holds this device's push token for the signed-in member, so delivery
    // still reaches the phone when the process is not running.
    ref.watch(pushTokenRegistrationProvider(currentUserId));

    // A tapped chat notification asks for a specific circle and the chat tab.
    // It is consumed once, after the frame, because switching the circle
    // rebuilds this screen with the new snapshot.
    final pendingChat = ref.watch(chatNotificationTargetProvider);
    if (pendingChat != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final target = ref.read(chatNotificationTargetProvider);
        if (target == null) return;
        ref.read(chatNotificationTargetProvider.notifier).clear();

        final memberships =
            ref.read(circlesProvider(currentUserId)).value ?? const [];
        if (!memberships.any((circle) => circle.id == target)) return;

        unawaited(
          ref
              .read(activeCircleControllerProvider(currentUserId).notifier)
              .select(target),
        );
        ref.read(activeTabControllerProvider.notifier).select(AppTab.chat);
      });
    }

    void select(AppTab target) =>
        ref.read(activeTabControllerProvider.notifier).select(target);

    void openMember(CircleMember member) {
      showMemberDetailSheet(
        context,
        memberId: member.profile.id,
        initialMember: member,
        isCurrentUser: member.profile.id == currentUserId,
        currentUserId: currentUserId,
      );
    }

    void showSharedLocation(GeoPoint point, String? label) {
      ref.read(mapFocusControllerProvider.notifier).focus(point, label: label);
      select(AppTab.map);
    }

    return MainShellScaffold(
      index: tab.index,
      onSelect: (index) => select(AppTab.values[index]),
      unreadChats: unreadChats,
      newMemories: newMemories,
      dockVisible: !(tab == AppTab.map && tripActive),
      overlay: activeNudge == null
          ? null
          : WarmthBanner(
              emoji: activeNudge.warmth.emoji,
              message: warmthBannerMessage(activeNudge, currentUserId),
              isIncoming: activeNudge.fromUserId != currentUserId,
            ),
      children: [
        CircleTab(
          key: ValueKey('circle-$circleId'),
          snapshot: snapshot,
          currentUserId: currentUserId,
        ),
        ChatTab(
          key: ValueKey('chat-$circleId'),
          circleId: circleId,
          currentUserId: currentUserId,
          active: tab == AppTab.chat,
          onShowLocation: showSharedLocation,
        ),
        MapTab(
          key: ValueKey('map-$circleId'),
          circleId: circleId,
          currentUserId: currentUserId,
          members: snapshot.members,
          onMemberTap: openMember,
          onChat: () => select(AppTab.chat),
          active: tab == AppTab.map,
        ),
        MemoriesTab(
          key: ValueKey('memories-$circleId'),
          circleId: circleId,
          currentUserId: currentUserId,
          circleName: circle.name,
          authors: {
            for (final member in snapshot.members)
              member.profile.id: member.profile,
          },
          onPlanMeetup: showSharedLocation,
        ),
        ProfileTab(
          key: const ValueKey('profile'),
          currentUserId: currentUserId,
        ),
      ],
    );
  }
}
