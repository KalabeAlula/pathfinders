import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/clock_provider.dart';
import '../../../circle/domain/circle_member.dart';
import '../../../location/application/telemetry_providers.dart';
import '../../../location/domain/geo_point.dart';
import '../../application/navigation_providers.dart';
import '../../domain/navigation_failure.dart';
import '../../domain/navigation_maneuver.dart';
import '../../domain/route_progress.dart';
import 'arrival_card.dart';
import 'maneuver_banner.dart';
import 'trip_summary_bar.dart';

/// Full-screen overlay for an active trip: maneuver banner at the top, trip
/// summary and exit at the bottom.
///
/// The middle stays empty so the angled camera has the whole road ahead.
class TripCockpit extends ConsumerWidget {
  const TripCockpit({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.members,
    this.onChat,
    this.unreadChats = 0,
  });

  final String circleId;
  final String currentUserId;
  final List<CircleMember> members;
  final VoidCallback? onChat;
  final int unreadChats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(navigationControllerProvider(circleId));
    final destination = navigation.destination;
    if (destination == null) return const SizedBox.shrink();

    final live = ref
        .watch(
          telemetryControllerProvider(
            currentUserId,
          ).select((state) => state.lastReading),
        )
        ?.point;
    final now = ref.watch(appClockProvider).value ?? DateTime.now();
    final selfRoute = navigation.routeFor(currentUserId);
    final current = live ?? _selfLocation() ?? selfRoute?.origin;

    final progress = selfRoute == null || current == null
        ? null
        : RouteProgress.from(selfRoute.plan, current, now: now);
    final maneuver = selfRoute == null || current == null
        ? null
        : NavigationManeuver.from(selfRoute.plan, current);

    final peers = <PeerTrip>[];
    for (final member in members) {
      if (member.profile.id == currentUserId) continue;
      final route = navigation.routeFor(member.profile.id);
      final point = member.status?.location;
      if (route == null || point == null) continue;
      peers.add(
        PeerTrip(
          profile: member.profile,
          progress: RouteProgress.from(route.plan, point, now: now),
        ),
      );
    }
    peers.sort(
      (a, b) => a.progress.remainingMeters.compareTo(b.progress.remainingMeters),
    );

    return Stack(
      children: [
        if (maneuver != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ManeuverBanner(
              maneuver: maneuver,
              onChat: onChat,
              unreadChats: unreadChats,
            ),
          ),
        Positioned(
          left: 12,
          right: 12,
          // The shell dock hides during a trip, so the bar sits alone above
          // the gesture area.
          bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ArrivalCard(
                circleId: circleId,
                currentUserId: currentUserId,
                compact: true,
              ),
              TripSummaryBar(
                destinationLabel: destination.label,
                progress: progress,
                peers: peers,
                error: navigation.error,
                onEnd: () => _endTrip(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  GeoPoint? _selfLocation() {
    for (final member in members) {
      if (member.profile.id == currentUserId) return member.status?.location;
    }
    return null;
  }

  Future<void> _endTrip(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(navigationRepositoryProvider(circleId))
          .clearDestination();
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Navigation ended.')),
      );
    } on NavigationFailure catch (failure) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}
