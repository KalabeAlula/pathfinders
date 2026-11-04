import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/battery_badge.dart';
import '../../../../app/widgets/member_avatar.dart';
import '../../domain/circle_member.dart';
import '../member_status_label.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.isCurrentUser,
    required this.now,
    required this.onTap,
    this.warmthEmoji,
    this.onWarmth,
    this.onWarmthOptions,
  });

  final CircleMember member;
  final bool isCurrentUser;
  final DateTime now;
  final VoidCallback onTap;
  final String? warmthEmoji;
  final VoidCallback? onWarmth;
  final VoidCallback? onWarmthOptions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = member.status;
    final online = status?.isOnlineAt(now) ?? false;
    final radius = BorderRadius.circular(AppRadius.tile);

    return SizedBox(
      width: 168,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: radius,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            onLongPress: onWarmthOptions,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MemberAvatar(
                        profile: member.profile,
                        size: 38,
                        isOnline: online,
                        isPaused: status?.isPaused ?? false,
                        isApproximate: status?.isApproximate ?? false,
                        showStatusBadge: status != null,
                      ),
                      const Spacer(),
                      if (status == null)
                        Tooltip(
                          message: 'No location update yet',
                          child: Icon(
                            Icons.sensors_off_rounded,
                            size: 16,
                            color: scheme.outline,
                          ),
                        )
                      else if (status.batteryPercent == null)
                        Tooltip(
                          message: 'No battery reading yet',
                          child: Icon(
                            Icons.battery_unknown_rounded,
                            size: 16,
                            color: scheme.outline,
                          ),
                        )
                      else
                        BatteryBadge(
                          percent: status.batteryPercent!,
                          isCharging: status.isCharging,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.profile.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 5),
                        _YouBadge(color: scheme.secondaryContainer),
                      ],
                      if (warmthEmoji != null) ...[
                        const Spacer(),
                        _WarmthButton(
                          emoji: warmthEmoji!,
                          memberId: member.profile.id,
                          memberName: member.profile.firstName,
                          onTap: onWarmth,
                          onLongPress: onWarmthOptions,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    describeMemberStatus(member, now),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarmthButton extends StatelessWidget {
  const _WarmthButton({
    required this.emoji,
    required this.memberId,
    required this.memberName,
    required this.onTap,
    required this.onLongPress,
  });

  final String emoji;
  final String memberId;
  final String memberName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

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

class _YouBadge extends StatelessWidget {
  const _YouBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'you',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
