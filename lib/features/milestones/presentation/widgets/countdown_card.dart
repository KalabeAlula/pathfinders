import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/bento_card.dart';
import '../../../../core/application/clock_provider.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/shared_milestone.dart';
import '../milestone_copy.dart';
import '../milestone_style.dart';

class CountdownCard extends ConsumerWidget {
  const CountdownCard({
    super.key,
    required this.milestone,
    this.now,
    this.onTap,
  });

  final SharedMilestone milestone;

  /// Pinned clock for tests; the card follows the app clock otherwise.
  final DateTime? now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = now ?? ref.watch(appClockProvider).value ?? DateTime.now();
    final days = milestone.daysFrom(clock);
    final displayDays = days < 0 ? 0 : days;
    final kind = milestone.kind;
    final start = milestone.startsAt;
    final time = start == null ? null : formatEventTime(start);
    final when = milestoneDayLine(milestone, clock);
    final place = milestone.place;
    final white = Colors.white;
    final faded = Colors.white.withValues(alpha: 0.72);

    return Semantics(
      label:
          '${milestone.title}, ${formatCountdown(days)}, '
          '${milestoneWhenLine(milestone, clock)}'
          '${place == null ? '' : ', $place'}',
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        semanticLabel: 'Plan ${milestone.title}.',
        gradient: LinearGradient(
          colors: kind.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: Colors.white.withValues(alpha: 0.14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(kind.icon, size: 12, color: faded),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          kind.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: faded,
                                fontSize: 8.5,
                                letterSpacing: 1.1,
                              ),
                        ),
                      ),
                      if (time != null) ...[
                        const SizedBox(width: 6),
                        _TimeBadge(label: time),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Text(
                    milestone.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    when,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: faded,
                      fontSize: 10.5,
                    ),
                  ),
                  if (place != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.place_rounded, size: 11, color: faded),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: faded, fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (days == 0 || days == 1) ...[
                  _NearBadge(
                    label: days == 0 ? 'Today' : 'Tomorrow',
                    onTap: onTap,
                  ),
                  const Spacer(),
                ],
                Text(
                  '$displayDays',
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(color: white, fontSize: 40, height: 0.95),
                ),
                Text(
                  days == 0
                      ? 'today'
                      : days == 1
                      ? 'day left'
                      : 'days left',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: faded, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NearBadge extends StatelessWidget {
  const _NearBadge({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: onTap != null,
      label: 'Open the plan. $label.',
      child: Material(
        key: const ValueKey('plan-soon-badge'),
        color: AppColors.linen,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 10,
                  color: AppColors.cocoa,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.cocoa,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
