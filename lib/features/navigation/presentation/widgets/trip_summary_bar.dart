import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/member_avatar.dart';
import '../../../../core/utils/time_format.dart';
import '../../../circle/domain/user_profile.dart';
import '../../domain/route_progress.dart';

/// One member's row in the peer strip.
class PeerTrip {
  const PeerTrip({required this.profile, required this.progress});

  final UserProfile profile;
  final RouteProgress progress;
}

/// Google Maps-style footer for an active trip.
///
/// [progress] is null while the first route is still in flight; the bar shows
/// a placeholder rather than disappearing, so the exit button never moves.
class TripSummaryBar extends StatelessWidget {
  const TripSummaryBar({
    super.key,
    required this.destinationLabel,
    required this.progress,
    required this.onEnd,
    this.peers = const [],
    this.error,
  });

  final String destinationLabel;
  final RouteProgress? progress;
  final List<PeerTrip> peers;
  final String? error;
  final Future<void> Function() onEnd;

  Future<void> _confirmEnd(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End navigation?'),
        content: Text(
          'This clears $destinationLabel for everyone in your circle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End trip'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onEnd();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trip = progress;
    final accent = theme.brightness == Brightness.dark
        ? const Color(0xFF9FD8B4)
        : AppColors.forest;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (peers.isNotEmpty) ...[
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: peers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, index) => _PeerChip(peer: peers[index]),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 12,
                            color: scheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'To $destinationLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (trip == null) ...[
                        Text(
                          error ?? 'Finding your route…',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: error == null
                                ? scheme.onSurfaceVariant
                                : scheme.error,
                          ),
                        ),
                      ] else ...[
                        Text(
                          trip.arrived
                              ? 'Arrived'
                              : formatTripTime(trip.remaining),
                          maxLines: 1,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: accent,
                          ),
                        ),
                        Text(
                          '${formatRouteDistance(trip.remainingMeters)} • '
                          '${formatArrivalClock(trip.arrival)}',
                          maxLines: 1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ExitButton(onPressed: () => _confirmEnd(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  const _ExitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'End navigation',
      child: Material(
        color: scheme.error,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(
              Icons.close_rounded,
              size: 26,
              color: scheme.onError,
            ),
          ),
        ),
      ),
    );
  }
}

class _PeerChip extends StatelessWidget {
  const _PeerChip({required this.peer});

  final PeerTrip peer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final arrived = peer.progress.arrived;
    final label = arrived
        ? 'Here'
        : formatTripTime(peer.progress.remaining);

    return Container(
      padding: const EdgeInsets.fromLTRB(3, 3, 9, 3),
      decoration: BoxDecoration(
        color: arrived
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MemberAvatar(
            profile: peer.profile,
            size: 24,
            showStatusBadge: false,
          ),
          const SizedBox(width: 6),
          Text(
            '${peer.profile.firstName}: $label',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: arrived ? scheme.onSecondaryContainer : scheme.onSurface,
            ),
          ),
          if (arrived) ...[
            const SizedBox(width: 3),
            Icon(Icons.check_circle_rounded, size: 12, color: scheme.tertiary),
          ],
        ],
      ),
    );
  }
}
