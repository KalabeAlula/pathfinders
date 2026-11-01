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
  });

  final CircleMember member;
  final bool isCurrentUser;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = member.status;
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
                        isOnline: status?.isOnline ?? false,
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 5),
                        _YouBadge(color: scheme.secondaryContainer),
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
