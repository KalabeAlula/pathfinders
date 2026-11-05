import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/glass_dock.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/battery_badge.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../app/widgets/member_avatar.dart';
import '../../../core/application/clock_provider.dart';
import '../../../features/pet/application/pet_providers.dart';
import '../../location/application/telemetry_providers.dart';
import '../../location/presentation/widgets/sharing_notice_banner.dart';
import '../../nudges/domain/nudge.dart';
import '../../nudges/presentation/warmth_actions.dart';
import '../../pet/application/pet_mood_providers.dart';
import '../../pet/domain/ethiopian_pet.dart';
import '../../pet/domain/pet_care_action.dart';
import '../../pet/domain/shared_pet.dart';
import '../../pet/presentation/pet_mood_visuals.dart';
import '../../pet/presentation/widgets/animated_pet_sticker.dart';
import '../../pet/presentation/widgets/companion_sheet.dart';
import '../../pet/presentation/widgets/pet_card.dart';
import '../application/circle_providers.dart';
import '../domain/circle_member.dart';
import '../domain/circle_snapshot.dart';
import 'member_status_label.dart';
import 'widgets/add_circle_sheet.dart';
import 'widgets/circle_hub_carousel.dart';
import 'widgets/circle_settings_sheet.dart';
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

  Future<void> _careForPet(
    BuildContext context,
    WidgetRef ref,
    PetCareAction action,
  ) async {
    try {
      await ref.read(petRepositoryProvider(snapshot.circle.id)).care(action);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach your companion.')),
      );
    }
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
    final openSeats = circle.capacity - snapshot.members.length;
    final mood = ref.watch(petMoodProvider(circle.id));
    final circles = ref.watch(circlesProvider(currentUserId)).value;

    void openCompanion() {
      showCompanionCard(
        context,
        pet: species,
        state: pet,
        mood: mood,
        groupType: circle.type,
        now: now,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your circles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        circles == null
                            ? 'Shared with ${circle.name}'
                            : '${circles.length} '
                                  '${circles.length == 1 ? 'circle' : 'circles'}'
                                  ' · sharing with ${circle.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                _RoundAction(
                  key: const ValueKey('circle-add'),
                  icon: Icons.add_rounded,
                  tooltip: 'Create or join a circle',
                  onTap: addCircle,
                ),
                const SizedBox(width: AppSpacing.sm),
                _RoundAction(
                  key: const ValueKey('circle-settings'),
                  icon: Icons.settings_outlined,
                  tooltip: 'Circle settings',
                  onTap: () => showCircleSettings(
                    context,
                    userId: currentUserId,
                    snapshot: snapshot,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CircleHubCarousel(
            userId: currentUserId,
            activeMood: mood,
            onAdd: addCircle,
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your circle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(circle.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  '${snapshot.members.length} of ${circle.capacity} '
                  '${snapshot.members.length == 1 ? 'member' : 'members'}'
                  ' · ${circle.type.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Tooltip(
                        message: 'Meet ${pet.name}',
                        child: AnimatedPetSticker(
                          pet: species,
                          mood: mood,
                          size: 72,
                          onTap: openCompanion,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GroupTypeBadge(
                                  type: circle.type,
                                  showIcon: true,
                                ),
                                const Spacer(),
                                if (openSeats > 0)
                                  Text(
                                    '$openSeats open '
                                    '${openSeats == 1 ? 'seat' : 'seats'}',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${pet.name} the ${species.commonName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${mood.label} · Level ${pet.level}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _InviteCard(
                  code: circle.inviteCode,
                  circleName: circle.name,
                  onCopy: () => _copyInviteCode(context),
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
                Text(
                  '${snapshot.onlineCount} online',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
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
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SizedBox(
              height: 164,
              child: PetCard(
                pet: pet,
                now: now,
                onCare: (action) => _careForPet(context, ref, action),
                onOpen: openCompanion,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.code,
    required this.circleName,
    required this.onCopy,
  });

  final String code;
  final String circleName;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.key_rounded,
                  size: 15,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'INVITE CODE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.tile),
                      onTap: onCopy,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 12,
                        ),
                        child: Text(
                          code,
                          key: const ValueKey('invite-code'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.tonalIcon(
                  key: const ValueKey('invite-copy'),
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Anyone with this code can join $circleName.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
                            message: 'Circle creator',
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
