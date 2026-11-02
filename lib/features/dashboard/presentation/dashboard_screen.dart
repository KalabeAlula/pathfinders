import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../core/application/clock_provider.dart';
import '../../../core/utils/time_format.dart';
import '../../chat/application/chat_providers.dart';
import '../../circle/domain/circle_member.dart';
import '../../circle/domain/circle_snapshot.dart';
import '../../circle/presentation/widgets/member_detail_sheet.dart';
import '../../circle/presentation/widgets/member_presence_header.dart';
import '../../location/application/telemetry_providers.dart';
import '../../location/domain/device_telemetry.dart';
import '../../location/domain/privacy_mode.dart';
import '../../location/presentation/widgets/live_map_card.dart';
import '../../memories/application/memories_providers.dart';
import '../../memories/domain/memory_post.dart';
import '../../memories/presentation/widgets/memory_composer_sheet.dart';
import '../../memories/presentation/widgets/memory_snippet_card.dart';
import '../../milestones/application/milestones_providers.dart';
import '../../milestones/domain/shared_milestone.dart';
import '../../milestones/presentation/widgets/countdown_card.dart';
import '../../milestones/presentation/widgets/milestone_composer_sheet.dart';
import '../../nudges/application/nudge_providers.dart';
import '../../nudges/domain/nudge.dart';
import '../../nudges/presentation/widgets/nudge_overlay.dart';
import '../../nudges/presentation/widgets/nudge_tile.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/pet_care_action.dart';
import '../../pet/domain/shared_pet.dart';
import '../../pet/presentation/widgets/pet_card.dart';
import 'widgets/dashboard_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    required this.snapshot,
    required this.currentUserId,
  });

  final CircleSnapshot snapshot;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(petControllerProvider);
    final activeNudge = ref.watch(nudgeControllerProvider);
    final telemetry = ref.watch(telemetryControllerProvider(currentUserId));
    final now = ref.watch(appClockProvider).value ?? DateTime.now();

    final circleId = snapshot.circle.id;
    // Keeps the unread baseline and the realtime stream warm while the crew is
    // on the dashboard, so the map badge counts messages that arrive meanwhile.
    ref.watch(
      chatUnreadCountProvider((circleId: circleId, userId: currentUserId)),
    );
    final memories =
        ref.watch(recentMemoriesProvider(circleId)).value ??
        const <MemoryPost>[];
    final milestones =
        ref.watch(milestonesProvider(circleId)).value ??
        const <SharedMilestone>[];

    SharedMilestone? milestone;
    for (final item in milestones) {
      if (item.daysFrom(now) >= 0) {
        milestone = item;
        break;
      }
    }

    void openMember(CircleMember member) {
      showMemberDetailSheet(
        context,
        memberId: member.profile.id,
        initialMember: member,
        isCurrentUser: member.profile.id == currentUserId,
        currentUserId: currentUserId,
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: _DashboardBody(
                snapshot: snapshot,
                currentUserId: currentUserId,
                pet: pet,
                memories: memories,
                milestone: milestone,
                now: now,
                sharingNotice: _sharingNotice(telemetry),
                onMemberTap: openMember,
                onSharingTap: () {
                  final me = snapshot.memberById(currentUserId);
                  if (me != null) openMember(me);
                },
                onCare: (action) =>
                    ref.read(petControllerProvider.notifier).care(action),
                onNudge: () => ref
                    .read(nudgeControllerProvider.notifier)
                    .sendNudge(
                      fromUserId: currentUserId,
                      recipientIds: snapshot.circle.memberIds,
                    ),
                onCopyInvite: () =>
                    _copyInviteCode(context, snapshot.circle.inviteCode),
                onAddMemory: () => showMemoryComposer(
                  context,
                  circleId: circleId,
                  authorId: currentUserId,
                ),
                onAddMilestone: () => showMilestoneComposer(
                  context,
                  circleId: circleId,
                  createdBy: currentUserId,
                ),
              ),
            ),
            if (activeNudge != null)
              Positioned.fill(
                child: NudgeOverlay(
                  title: activeNudge.kind.label,
                  message: _nudgeMessage(activeNudge, snapshot, currentUserId),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyInviteCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code $code copied. Share it with your crew.'),
      ),
    );
  }

  String _nudgeMessage(
    NudgePing ping,
    CircleSnapshot snapshot,
    String currentUserId,
  ) {
    final sender =
        snapshot.memberById(currentUserId)?.profile.firstName ?? 'You';
    if (ping.isGroupNudge) return '$sender nudged the whole crew';
    final recipient = snapshot.memberById(ping.recipientIds.first);
    return '$sender nudged ${recipient?.profile.firstName ?? 'the crew'}';
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.snapshot,
    required this.currentUserId,
    required this.pet,
    required this.memories,
    required this.milestone,
    required this.now,
    required this.sharingNotice,
    required this.onMemberTap,
    required this.onSharingTap,
    required this.onCare,
    required this.onNudge,
    required this.onCopyInvite,
    required this.onAddMemory,
    required this.onAddMilestone,
  });

  final CircleSnapshot snapshot;
  final String currentUserId;
  final AsyncValue<SharedPet> pet;
  final List<MemoryPost> memories;
  final SharedMilestone? milestone;
  final DateTime now;
  final _SharingNotice? sharingNotice;
  final ValueChanged<CircleMember> onMemberTap;
  final VoidCallback onSharingTap;
  final ValueChanged<PetCareAction> onCare;
  final VoidCallback onNudge;
  final VoidCallback onCopyInvite;
  final VoidCallback onAddMemory;
  final VoidCallback onAddMilestone;

  @override
  Widget build(BuildContext context) {
    final currentMember = snapshot.memberById(currentUserId);
    final firstName = currentMember?.profile.firstName ?? 'friend';
    final latestMemory = memories.isEmpty ? null : memories.first;

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: DashboardHeader(
            greeting: greetingFor(now),
            firstName: firstName,
            circleName: snapshot.circle.name,
            dateLine: formatDateLine(now),
            inviteCode: snapshot.circle.inviteCode,
            onCopyInvite: onCopyInvite,
          ),
        ),
        const SizedBox(height: 18),
        MemberPresenceHeader(
          members: snapshot.members,
          currentUserId: currentUserId,
          now: now,
          onMemberTap: onMemberTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            18,
            AppSpacing.xl,
            0,
          ),
          child: Column(
            children: [
              if (sharingNotice != null) ...[
                _SharingBanner(notice: sharingNotice!, onTap: onSharingTap),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                height: 196,
                child: LiveMapCard(
                  circleId: snapshot.circle.id,
                  members: snapshot.members,
                  currentUserId: currentUserId,
                  onMemberTap: onMemberTap,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              pet.when(
                data: (value) => SizedBox(
                  height: 164,
                  child: PetCard(pet: value, now: now, onCare: onCare),
                ),
                loading: () => const _SkeletonBox(height: 164),
                error: (error, stack) => const _SkeletonBox(height: 164),
              ),
              const SizedBox(height: AppSpacing.md),
              if (latestMemory != null)
                MemorySnippetCard(
                  memory: latestMemory,
                  author: snapshot.memberById(latestMemory.authorId)?.profile,
                  now: now,
                  onTap: onAddMemory,
                )
              else
                _EmptyMemoryCard(onTap: onAddMemory),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 124,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: milestone == null
                          ? _EmptyMilestoneCard(onTap: onAddMilestone)
                          : CountdownCard(
                              milestone: milestone!,
                              now: now,
                              onTap: onAddMilestone,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: NudgeTile(onSend: onNudge)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

typedef _SharingNotice = ({String text, IconData icon});

_SharingNotice? _sharingNotice(TelemetryState telemetry) {
  final permission = telemetry.permission;
  if (permission == null) return null;

  if (permission == TelemetryPermission.unsupported) {
    return (
      text: 'Live location is not available on this device',
      icon: Icons.location_disabled_rounded,
    );
  }
  if (permission != TelemetryPermission.granted) {
    return (
      text: 'Location is off — tap to start sharing',
      icon: Icons.location_off_rounded,
    );
  }
  if (telemetry.mode == PrivacyMode.paused) {
    return (
      text: 'Sharing paused — the crew sees battery only',
      icon: Icons.pause_circle_outline_rounded,
    );
  }
  return null;
}

class _SharingBanner extends StatelessWidget {
  const _SharingBanner({required this.notice, required this.onTap});

  final _SharingNotice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.tile);

    return Material(
      color: scheme.tertiaryContainer.withValues(alpha: 0.7),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Icon(notice.icon, size: 16, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notice.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: scheme.onTertiaryContainer),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.onTertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMemoryCard extends StatelessWidget {
  const _EmptyMemoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BentoCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      semanticLabel: 'Add your first memory.',
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No memories yet',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Drop the first little moment here — a photo, a note, a voice clip.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.add_circle_outline_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _EmptyMilestoneCard extends StatelessWidget {
  const _EmptyMilestoneCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BentoCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      semanticLabel: 'Add your first countdown.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const Spacer(),
              Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Nothing on the horizon',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            'Add a countdown for the next thing you all care about.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
    );
  }
}

extension on NudgeKind {
  String get label => switch (this) {
    NudgeKind.thinkingOfYou => 'Thinking of you',
    NudgeKind.onMyWay => 'On my way',
    NudgeKind.needYou => 'Missing you',
  };
}
