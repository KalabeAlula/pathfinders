import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/application/clock_provider.dart';
import '../../../../core/utils/time_format.dart';
import '../../../circle/domain/circle_member.dart';
import '../../../location/application/telemetry_providers.dart';
import '../../../location/presentation/widgets/map_circle_view.dart';
import '../../application/navigation_providers.dart';
import '../../domain/route_progress.dart';

/// Bottom HUD for an active trip: every routed member's remaining distance,
/// travel time, and arrival clock.
class RouteEtaCard extends ConsumerWidget {
  const RouteEtaCard({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.members,
  });

  final String circleId;
  final String currentUserId;
  final List<CircleMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(navigationControllerProvider(circleId));
    final destination = navigation.destination;
    if (destination == null || navigation.routes.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final live = ref
        .watch(
          telemetryControllerProvider(currentUserId)
              .select((state) => state.lastReading),
        )
        ?.point;
    final colors = routeAccentColors(
      members: members,
      currentUserId: currentUserId,
      scheme: scheme,
    );
    final now = ref.watch(appClockProvider).value ?? DateTime.now();

    final rows = <_MemberEta>[];
    for (final member in members) {
      final route = navigation.routeFor(member.profile.id);
      if (route == null) continue;

      final isMe = member.profile.id == currentUserId;
      final current = isMe
          ? (live ?? member.status?.location ?? route.origin)
          : (member.status?.location ?? route.origin);

      rows.add(
        _MemberEta(
          name: isMe ? 'You' : member.profile.firstName,
          color: colors[member.profile.id] ?? scheme.primary,
          isMe: isMe,
          progress: RouteProgress.from(route.plan, current, now: now),
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    rows.sort((a, b) {
      if (a.isMe == b.isMe) return a.name.compareTo(b.name);
      return a.isMe ? -1 : 1;
    });

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 14, color: scheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Heading to ${destination.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (navigation.loadingMemberIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const SizedBox(height: 4),
              _EtaRow(row: rows[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberEta {
  const _MemberEta({
    required this.name,
    required this.color,
    required this.isMe,
    required this.progress,
  });

  final String name;
  final Color color;
  final bool isMe;
  final RouteProgress progress;
}

class _EtaRow extends StatelessWidget {
  const _EtaRow({required this.row});

  final _MemberEta row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = row.progress;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: row.color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            row.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: row.isMe ? FontWeight.w700 : FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (progress.arrived)
          Text(
            'Arrived',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.tertiary,
            ),
          )
        else ...[
          Text(
            '${formatRouteDistance(progress.remainingMeters)} · '
            '${formatRouteEta(progress.remaining)}',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Text(
            formatArrivalClock(progress.arrival),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}
