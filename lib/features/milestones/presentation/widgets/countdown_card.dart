import 'package:flutter/material.dart';

import '../../../../app/widgets/bento_card.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/shared_milestone.dart';

class CountdownCard extends StatelessWidget {
  const CountdownCard({
    super.key,
    required this.milestone,
    required this.now,
  });

  final SharedMilestone milestone;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final days = milestone.daysFrom(now);
    final displayDays = days < 0 ? 0 : days;
    final kind = milestone.kind;
    final white = Colors.white;
    final faded = Colors.white.withValues(alpha: 0.72);

    return Semantics(
      label:
          '${milestone.title}, ${formatCountdown(days)}. ${milestone.subtitle ?? ''}',
      child: BentoCard(
        padding: const EdgeInsets.all(16),
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
                      Text(
                        kind.label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: faded,
                              fontSize: 8.5,
                              letterSpacing: 1.1,
                            ),
                      ),
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
                    formatMilestoneDate(milestone.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: faded,
                          fontSize: 10.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$displayDays',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: white,
                        fontSize: 40,
                        height: 0.95,
                      ),
                ),
                Text(
                  days == 0
                      ? 'today'
                      : days == 1
                          ? 'day left'
                          : 'days left',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: faded,
                        fontSize: 9,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on MilestoneKind {
  List<Color> get colors => switch (this) {
        MilestoneKind.birthday => const [Color(0xFFB86B4F), Color(0xFF8F4B36)],
        MilestoneKind.anniversary => const [
            Color(0xFF8D6F88),
            Color(0xFF5E4659),
          ],
        MilestoneKind.trip => const [Color(0xFF7C8C6B), Color(0xFF56654A)],
        MilestoneKind.goal => const [Color(0xFFC7974C), Color(0xFF8E6A2F)],
      };

  IconData get icon => switch (this) {
        MilestoneKind.birthday => Icons.cake_rounded,
        MilestoneKind.anniversary => Icons.favorite_rounded,
        MilestoneKind.trip => Icons.luggage_rounded,
        MilestoneKind.goal => Icons.flag_rounded,
      };

  String get label => switch (this) {
        MilestoneKind.birthday => 'Birthday',
        MilestoneKind.anniversary => 'Milestone',
        MilestoneKind.trip => 'Trip',
        MilestoneKind.goal => 'Goal',
      };
}
