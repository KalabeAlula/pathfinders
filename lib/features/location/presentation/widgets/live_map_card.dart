import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/bento_card.dart';
import '../../../../app/widgets/member_avatar.dart';
import '../../../../core/utils/time_format.dart';
import '../../../circle/domain/circle_member.dart';
import '../../../navigation/application/navigation_providers.dart';
import '../../../navigation/application/navigation_state.dart';
import '../../../navigation/presentation/widgets/destination_sheet.dart';

class LiveMapCard extends ConsumerStatefulWidget {
  const LiveMapCard({
    super.key,
    required this.circleId,
    required this.members,
    required this.currentUserId,
    required this.onMemberTap,
  });

  final String circleId;
  final List<CircleMember> members;
  final String currentUserId;
  final ValueChanged<CircleMember> onMemberTap;

  @override
  ConsumerState<LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends ConsumerState<LiveMapCard> {
  final MapController _mapController = MapController();

  static const _fitInterval = Duration(seconds: 2);
  static const _peerRouteColors = <Color>[
    Color(0xFF3F6FA8),
    Color(0xFF6F9E62),
    Color(0xFF8C5BA8),
    Color(0xFFC7974C),
    Color(0xFF4A9A9A),
  ];

  bool _mapReady = false;
  DateTime? _lastFitAt;
  Timer? _fitTimer;
  List<LatLng> _pendingFit = const [];
  String? _pendingFitSignature;

  @override
  void dispose() {
    _fitTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _openDestinationSheet() {
    showDestinationSheet(
      context,
      circleId: widget.circleId,
      currentUserId: widget.currentUserId,
    );
  }

  /// Keeps every located member and the shared destination in frame. Fits are
  /// throttled so new GPS fixes do not yank the camera around constantly.
  void _scheduleFit(List<LatLng> points) {
    if (points.isEmpty || !_mapReady) return;

    final signature = [
      for (final point in points)
        '${point.latitude.toStringAsFixed(3)},'
            '${point.longitude.toStringAsFixed(3)}',
    ].join('|');
    if (signature == _pendingFitSignature) return;

    _pendingFitSignature = signature;
    _pendingFit = List.unmodifiable(points);

    final now = DateTime.now();
    final last = _lastFitAt;
    final elapsed = last == null ? null : now.difference(last);
    final remaining = elapsed == null || elapsed >= _fitInterval
        ? Duration.zero
        : _fitInterval - elapsed;

    _fitTimer?.cancel();
    if (remaining == Duration.zero) {
      _fitNow();
    } else {
      _fitTimer = Timer(remaining, _fitNow);
    }
  }

  void _fitNow() {
    if (!mounted || !_mapReady || _pendingFit.isEmpty) return;
    _lastFitAt = DateTime.now();
    final fit = CameraFit.coordinates(
      coordinates: _pendingFit,
      padding: const EdgeInsets.fromLTRB(46, 52, 46, 60),
      maxZoom: 15,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _mapController.fitCamera(fit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final navigation = ref.watch(navigationControllerProvider(widget.circleId));
    final destination = navigation.destination;

    final located = widget.members
        .where((member) => member.status?.location != null)
        .toList(growable: false);
    final points = [
      for (final member in located)
        LatLng(
          member.status!.location!.latitude,
          member.status!.location!.longitude,
        ),
    ];
    final destinationPoint = destination == null
        ? null
        : LatLng(destination.latitude, destination.longitude);
    final fitPoints = [
      ...points,
      ?destinationPoint,
    ];

    final pausedCount = widget.members
        .where((member) => member.status?.isPaused ?? false)
        .length;

    final peerIds = [
      for (final member in widget.members)
        if (member.profile.id != widget.currentUserId) member.profile.id,
    ]..sort();
    final routeColors = <String, Color>{
      for (final member in widget.members)
        member.profile.id: member.profile.id == widget.currentUserId
            ? scheme.primary
            : _peerRouteColors[
                peerIds.indexOf(member.profile.id) % _peerRouteColors.length],
    };

    final routes = [
      for (final member in widget.members)
        if (navigation.routeFor(member.profile.id) case final route?)
          (member: member, route: route),
    ]..sort(
        (a, b) => a.member.profile.id == widget.currentUserId
            ? 1
            : b.member.profile.id == widget.currentUserId
                ? -1
                : 0,
      );

    _scheduleFit(fitPoints);

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: destinationPoint ??
            (points.isEmpty ? const LatLng(8.999, 38.775) : points.first),
        initialZoom: 14.5,
        backgroundColor: scheme.surfaceContainerHigh,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
        onMapReady: () {
          _mapReady = true;
          _lastFitAt = null;
          _pendingFitSignature = null;
          _scheduleFit(fitPoints);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pathfinders.pathfinders',
        ),
        PolylineLayer(
          polylines: [
            for (final entry in routes)
              Polyline(
                points: [
                  for (final point in entry.route.plan.geometry)
                    LatLng(point.latitude, point.longitude),
                ],
                strokeWidth:
                    entry.member.profile.id == widget.currentUserId ? 5.5 : 4,
                color: routeColors[entry.member.profile.id]!,
                borderStrokeWidth: 1.5,
                borderColor: Colors.white.withValues(alpha: 0.9),
              ),
          ],
        ),
        if (destinationPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: destinationPoint,
                width: 44,
                height: 50,
                child: _DestinationMarker(color: scheme.tertiary),
              ),
            ],
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
                  isCurrentUser: member.profile.id == widget.currentUserId,
                  accent: routeColors[member.profile.id],
                  hasRoute: navigation.routeFor(member.profile.id) != null,
                  onTap: () => widget.onMemberTap(member),
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
              right: 12,
              child: Row(
                children: [
                  _MapPill(
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
                              : 'Live · ${located.length}/${widget.members.length}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _MapAction(
                    icon: destination == null
                        ? Icons.flag_outlined
                        : Icons.flag_rounded,
                    label: destination?.label ?? 'Meet up',
                    accent: destination == null ? null : scheme.tertiary,
                    onTap: _openDestinationSheet,
                  ),
                ],
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
            Positioned(
              left: 12,
              right: 78,
              bottom: 10,
              child: Row(
                children: [
                  if (pausedCount > 0) ...[
                    _MapPill(
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
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: _NavigationStatus(
                      destinationSet: destination != null,
                      isConfigured: navigation.isConfigured,
                      hasRoutes: routes.isNotEmpty,
                      error: navigation.error,
                      routes: routes,
                      routeColors: routeColors,
                      currentUserId: widget.currentUserId,
                      onTap: _openDestinationSheet,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationStatus extends StatelessWidget {
  const _NavigationStatus({
    required this.destinationSet,
    required this.isConfigured,
    required this.hasRoutes,
    required this.error,
    required this.routes,
    required this.routeColors,
    required this.currentUserId,
    required this.onTap,
  });

  final bool destinationSet;
  final bool isConfigured;
  final bool hasRoutes;
  final String? error;
  final List<({CircleMember member, MemberRoute route})> routes;
  final Map<String, Color> routeColors;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!destinationSet) return const SizedBox.shrink();

    if (!hasRoutes) {
      final label = !isConfigured
          ? 'Add Mapbox token to route'
          : error != null
              ? 'Routes unavailable'
              : 'Calculating routes…';
      final icon = !isConfigured
          ? Icons.key_rounded
          : error != null
              ? Icons.warning_amber_rounded
              : null;

      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          child: _MapPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: 12,
                    color: error != null
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                else
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in routes)
            _RouteChip(
              name: entry.member.profile.id == currentUserId
                  ? 'You'
                  : entry.member.profile.firstName,
              eta: formatRouteEta(entry.route.plan.duration),
              color: routeColors[entry.member.profile.id]!,
            ),
        ],
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.name,
    required this.eta,
    required this.color,
  });

  final String name;
  final String eta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            '$name $eta',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          Container(
            width: 3,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberMarker extends StatelessWidget {
  const _MemberMarker({
    required this.member,
    required this.isCurrentUser,
    required this.accent,
    required this.hasRoute,
    required this.onTap,
  });

  final CircleMember member;
  final bool isCurrentUser;
  final Color? accent;
  final bool hasRoute;
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
                color: accent ??
                    (isCurrentUser
                        ? scheme.primary
                        : scheme.surfaceContainerLowest),
                width: hasRoute ? 2.5 : 2,
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

class _MapAction extends StatelessWidget {
  const _MapAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest.withValues(alpha: 0.94),
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: accent ?? scheme.primary),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 104),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
