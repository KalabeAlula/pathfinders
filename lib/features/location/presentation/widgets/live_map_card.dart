import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/bento_card.dart';
import '../../../../app/widgets/member_avatar.dart';
import '../../../circle/domain/circle_member.dart';

class LiveMapCard extends StatelessWidget {
  const LiveMapCard({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.onMemberTap,
  });

  final List<CircleMember> members;
  final String currentUserId;
  final ValueChanged<CircleMember> onMemberTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final located = members
        .where((member) => member.status?.location != null)
        .toList(growable: false);
    final points = [
      for (final member in located)
        LatLng(
          member.status!.location!.latitude,
          member.status!.location!.longitude,
        ),
    ];
    final pausedCount =
        members.where((member) => member.status?.isPaused ?? false).length;
    final bounds = points.length > 1 ? LatLngBounds.fromPoints(points) : null;

    final map = FlutterMap(
      options: MapOptions(
        initialCenter:
            points.isEmpty ? const LatLng(8.999, 38.775) : points.first,
        initialZoom: points.length <= 1 ? 14.5 : 12.5,
        initialCameraFit: bounds == null
            ? null
            : CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.fromLTRB(44, 48, 44, 58),
                maxZoom: 14.5,
              ),
        backgroundColor: scheme.surfaceContainerHigh,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pathfinders.app',
        ),
        MarkerLayer(
          markers: [
            for (final member in located.reversed)
              Marker(
                point: LatLng(
                  member.status!.location!.latitude,
                  member.status!.location!.longitude,
                ),
                width: 58,
                height: 62,
                child: _MemberMarker(
                  member: member,
                  isCurrentUser: member.profile.id == currentUserId,
                  onTap: () => onMemberTap(member),
                ),
              ),
          ],
        ),
        SimpleAttributionWidget(
          source: Text(
            'OpenStreetMap',
            style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
          ),
          backgroundColor: scheme.surfaceContainerLowest.withValues(alpha: 0.85),
        ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: BentoCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(child: map),
            Positioned(
              top: 12,
              left: 12,
              child: _MapPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (located.isEmpty)
                      Icon(
                        Icons.schedule_rounded,
                        size: 11,
                        color: scheme.onSurfaceVariant,
                      )
                    else
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF6F9E62),
                        ),
                      ),
                    const SizedBox(width: 5),
                    Text(
                      located.isEmpty
                          ? 'Waiting for locations'
                          : 'Live · ${located.length}/${members.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
            if (pausedCount > 0)
              Positioned(
                left: 12,
                bottom: 14,
                child: _MapPill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$pausedCount paused',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            if (located.isEmpty)
              Positioned.fill(
                child: Center(
                  child: _MapPill(
                    child: Text(
                      'No live locations yet',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberMarker extends StatelessWidget {
  const _MemberMarker({
    required this.member,
    required this.isCurrentUser,
    required this.onTap,
  });

  final CircleMember member;
  final bool isCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = member.status;
    if (status == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status.isApproximate
                  ? scheme.tertiaryContainer.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isCurrentUser
                    ? scheme.primary
                    : scheme.surfaceContainerLowest,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: MemberAvatar(
              profile: member.profile,
              size: 30,
              isOnline: status.isOnline,
              showStatusBadge: false,
            ),
          ),
          if (status.batteryPercent != null) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status.isCharging
                        ? Icons.bolt_rounded
                        : Icons.battery_3_bar_rounded,
                    size: 9,
                    color: status.isLowBattery
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${status.batteryPercent}%',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: status.isLowBattery
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onSurface),
        child: child,
      ),
    );
  }
}
