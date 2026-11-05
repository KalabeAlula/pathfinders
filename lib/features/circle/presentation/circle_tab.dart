import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/glass_dock.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/battery_badge.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../app/widgets/member_avatar.dart';
import '../../../core/application/clock_provider.dart';
import '../../location/application/telemetry_providers.dart';
import '../../location/presentation/widgets/sharing_notice_banner.dart';
import '../../nudges/domain/nudge.dart';
import '../../nudges/presentation/warmth_actions.dart';
import '../../pet/application/pet_mood_providers.dart';
import '../../pet/domain/ethiopian_pet.dart';
import '../../pet/domain/shared_pet.dart';
import '../../pet/presentation/pet_mood_visuals.dart';
import '../../pet/presentation/widgets/animated_pet_sticker.dart';
import '../../pet/presentation/widgets/companion_sheet.dart';
import '../domain/circle_member.dart';
import '../domain/circle_snapshot.dart';
import 'member_status_label.dart';
import 'widgets/add_circle_sheet.dart';
import 'widgets/circle_settings_sheet.dart';
import 'widgets/circle_switcher.dart';
import 'widgets/group_type_badge.dart';
import 'widgets/member_detail_sheet.dart';

/// The circle tab: who is in it, how they are doing, the invite code and the
/// door to the membership settings.
class CircleTab extends ConsumerWidget {
  const CircleTab({
    super.key,
    required this.snapshot,
    required this.currentUserId,
  });

  final CircleSnapshot snapshot;
  final String currentUserId;

  void _openMember(
    BuildContext context,
    CircleMember member,
  ) {
    showMemberDetailSheet(
      context,
      memberId: member.profile.id,
      initialMember: member,
      isCurrentUser: member.profile.id == currentUserId,
      currentUserId: currentUserId,
    );
  }

  Future<void> _copyInviteCode(BuildContext context) async {
    final code = snapshot.circle.inviteCode;
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invite code $code copied.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final circle = snapshot.circle;
    final now = ref.watch(appClockProvider).value ?? DateTime.now();
    final petState = SharedPet.fromCircle(circle);
    final pet = petState.decayed(now.difference(petState.updatedAt), now);
    final species = EthiopianPet.byId(circle.petId);
    final sharingNotice = ref.watch(
      telemetryControllerProvider(currentUserId).select(sharingNoticeFor),
    );
    final quickEmoji = NudgeWarmth.defaultFor(circle.type).emoji;
    final mood = ref.watch(petMoodProvider(circle.id));

    void openCompanion() {
      showCompanionCard(
        context,
        circleId: circle.id,
        currentUserId: currentUserId,
        pet: species,
        mood: mood,
        groupType: circle.type,
      );
    }

    void addCircle() => showAddCircleSheet(context, userId: currentUserId);

    void quickWarmth(CircleMember member) => sendWarmth(
      context,
      ref,
      snapshot: snapshot,
      currentUserId: currentUserId,
      member: member,
      warmth: NudgeWarmth.defaultFor(circle.type),
    );

    void warmthOptions(CircleMember member) => pickWarmth(
      context,
      ref,
      snapshot: snapshot,
      currentUserId: currentUserId,
      member: member,
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.xxl + ShellDock.contentInset(context),
        ),
        children: [
          // Hero: the one circle and its one companion.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE CIRCLE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        circle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GroupTypeBadge(type: circle.type, showIcon: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sharingNotice != null) ...[
                  SharingNoticeBanner(
                    notice: sharingNotice,
                    onTap: () {
                      final me = snapshot.memberById(currentUserId);
                      if (me != null) _openMember(context, me);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                BentoCard(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      Tooltip(
                        message: 'Meet ${pet.name}',
                        child: AnimatedPetSticker(
                          pet: species,
                          mood: mood,
                          size: 112,
                          onTap: openCompanion,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${mood.label} · Level ${pet.level}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Icon(
                            Icons.group_rounded,
                            size: 15,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${snapshot.members.length} of '
                              '${circle.capacity} '
                              '${snapshot.members.length == 1 ? 'member' : 'members'}'
                              ' • ${snapshot.onlineCount} active now',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FilledButton.tonalIcon(
                            key: const ValueKey('invite-copy'),
                            onPressed: () => _copyInviteCode(context),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 16,
                            ),
                            label: const Text('Invite'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Text('Members', style: theme.textTheme.titleMedium),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final member in snapshot.members)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: _MemberRow(
                member: member,
                isCurrentUser: member.profile.id == currentUserId,
                isCreator: member.profile.id == circle.createdBy,
                now: now,
                warmthEmoji: member.profile.id == currentUserId
                    ? null
                    : quickEmoji,
                onTap: () => _openMember(context, member),
                onWarmth: () => quickWarmth(member),
                onWarmthOptions: () => warmthOptions(member),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('circle-settings'),
                onPressed: () => showCircleSettings(
                  context,
                  userId: currentUserId,
                  snapshot: snapshot,
                ),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Circle settings'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Switch circle',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CircleSwitcher(userId: currentUserId, onAdd: addCircle),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isCurrentUser,
    required this.isCreator,
    required this.now,
    required this.onTap,
    required this.onWarmth,
    required this.onWarmthOptions,
    this.warmthEmoji,
  });

  final CircleMember member;
  final bool isCurrentUser;
  final bool isCreator;
  final DateTime now;
  final String? warmthEmoji;
  final VoidCallback onTap;
  final VoidCallback onWarmth;
  final VoidCallback onWarmthOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = member.status;
    final online = status?.isOnlineAt(now) ?? false;
    final radius = BorderRadius.circular(AppRadius.tile);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              MemberAvatar(
                profile: member.profile,
                size: 40,
                isOnline: online,
                isPaused: status?.isPaused ?? false,
                isApproximate: status?.isApproximate ?? false,
                showStatusBadge: status != null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.profile.firstName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 5),
                          _Pill(label: 'you'),
                        ],
                        if (isCreator) ...[
                          const SizedBox(width: 5),
                          Tooltip(
                            message: 'Group creator',
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              size: 14,
                              color: scheme.tertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      describeMemberStatus(member, now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (status?.batteryPercent == null)
                    Icon(
                      Icons.battery_unknown_rounded,
                      size: 15,
                      color: scheme.outline,
                    )
                  else
                    BatteryBadge(
                      percent: status!.batteryPercent!,
                      isCharging: status.isCharging,
                    ),
                  if (warmthEmoji != null) ...[
                    const SizedBox(height: 4),
                    _WarmthPill(
                      emoji: warmthEmoji!,
                      memberId: member.profile.id,
                      memberName: member.profile.firstName,
                      onTap: onWarmth,
                      onLongPress: onWarmthOptions,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _WarmthPill extends StatelessWidget {
  const _WarmthPill({
    required this.emoji,
    required this.memberId,
    required this.memberName,
    required this.onTap,
    required this.onLongPress,
  });

  final String emoji;
  final String memberId;
  final String memberName;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Send $memberName warmth. Hold for more options.',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey('warmth-$memberId'),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ),
    );
  }
}
