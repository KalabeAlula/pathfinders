import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/application/chat_providers.dart';
import '../../features/chat/presentation/chat_tab.dart';
import '../../features/circle/domain/circle_member.dart';
import '../../features/circle/domain/circle_snapshot.dart';
import '../../features/circle/presentation/circle_tab.dart';
import '../../features/circle/presentation/widgets/member_detail_sheet.dart';
import '../../features/location/application/telemetry_providers.dart';
import '../../features/location/domain/geo_point.dart';
import '../../features/memories/presentation/memories_tab.dart';
import '../../features/navigation/application/map_focus_providers.dart';
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
    final activeNudge = ref.watch(
      nudgeControllerProvider(circleId, currentUserId),
    );

    // The shell stays mounted for the whole signed-in session, so watching the
    // heartbeat here keeps sharing alive across every tab.
    ref.listen(telemetryControllerProvider(currentUserId), (_, _) {});

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
        ),
        ProfileTab(
          key: const ValueKey('profile'),
          currentUserId: currentUserId,
        ),
      ],
    );
  }
}
