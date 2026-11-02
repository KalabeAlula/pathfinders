import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/bento_card.dart';
import '../../../../core/config/mapbox_config.dart';
import '../../../../core/utils/time_format.dart';
import '../../../circle/domain/circle_member.dart';
import '../../../navigation/application/navigation_providers.dart';
import '../../../navigation/application/navigation_state.dart';
import '../../../navigation/domain/route_progress.dart';
import '../../../navigation/presentation/destination_picker_screen.dart';
import '../../../navigation/presentation/widgets/destination_sheet.dart';
import '../../application/telemetry_providers.dart';
import '../../domain/geo_point.dart';
import 'map_circle_view.dart';
import 'mapbox_live_annotations.dart';
import 'mapbox_standard_style.dart';

const _fallbackCenter = GeoPoint(latitude: 8.999, longitude: 38.775);

class LiveMapCard extends ConsumerWidget {
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

  void _openDestinationSheet(BuildContext context) {
    showDestinationSheet(
      context,
      circleId: circleId,
      currentUserId: currentUserId,
      members: members,
      onMemberTap: onMemberTap,
    );
  }

  void _openPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DestinationPickerScreen(
          circleId: circleId,
          currentUserId: currentUserId,
          members: members,
          onMemberTap: onMemberTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navigation = ref.watch(navigationControllerProvider(circleId));
    final destination = navigation.destination;
    final livePoint = ref
        .watch(telemetryControllerProvider(currentUserId))
        .lastReading
        ?.point;
    final view = MapCircleView.from(
      members: members,
      currentUserId: currentUserId,
      navigation: navigation,
      scheme: scheme,
    );

    final destinationPoint = destination == null
        ? null
        : GeoPoint(
            latitude: destination.latitude,
            longitude: destination.longitude,
          );
    final initialCenter =
        destinationPoint ??
        (view.pins.isEmpty ? null : _pinPoint(view.pins.first));

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: BentoCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: _MapPreview(
                pins: view.pins,
                routes: view.lines,
                destination: destinationPoint,
                destinationColor: scheme.tertiary,
                initialCenter: initialCenter ?? _fallbackCenter,
                darkMode: theme.brightness == Brightness.dark,
                onMemberTapped: (memberId) {
                  for (final member in members) {
                    if (member.profile.id == memberId) {
                      onMemberTap(member);
                      return;
                    }
                  }
                },
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openPicker(context),
              ),
            ),
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
                        if (view.locatedCount == 0)
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
                          view.locatedCount == 0
                              ? 'Waiting for locations'
                              : 'Live · ${view.locatedCount}/${members.length}',
                          style: theme.textTheme.labelSmall,
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
                    onTap: () => _openDestinationSheet(context),
                  ),
                ],
              ),
            ),
            if (view.locatedCount == 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: _MapPill(
                      child: Text(
                        'No live locations yet',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 68,
              bottom: 10,
              child: Row(
                children: [
                  if (view.pausedCount > 0) ...[
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
                            '${view.pausedCount} paused',
                            style: theme.textTheme.labelSmall,
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
                      hasRoutes: view.routes.isNotEmpty,
                      error: navigation.error,
                      routes: view.routes,
                      routeColors: view.colors,
                      currentUserId: currentUserId,
                      livePoint: livePoint,
                      onTap: () => _openDestinationSheet(context),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 10,
              child: _PickOnMapButton(onTap: () => _openPicker(context)),
            ),
          ],
        ),
      ),
    );
  }

  static GeoPoint _pinPoint(MapMemberPin pin) =>
      GeoPoint(latitude: pin.latitude, longitude: pin.longitude);
}

/// The live preview. It never takes gestures itself; the card opens the
/// interactive picker instead, which keeps the dashboard scrollable.
class _MapPreview extends StatefulWidget {
  const _MapPreview({
    required this.pins,
    required this.routes,
    required this.destination,
    required this.destinationColor,
    required this.initialCenter,
    required this.darkMode,
    required this.onMemberTapped,
  });

  final List<MapMemberPin> pins;
  final List<MapRouteLine> routes;
  final GeoPoint? destination;
  final Color destinationColor;
  final GeoPoint initialCenter;
  final bool darkMode;
  final ValueChanged<String> onMemberTapped;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  static const _fitInterval = Duration(seconds: 2);

  late final ViewportState _viewport = CameraViewportState(
    center: Point(
      coordinates: Position(
        widget.initialCenter.longitude,
        widget.initialCenter.latitude,
      ),
    ),
    zoom: 14.5,
    pitch: MapboxStandardStyle.previewPitch,
  );

  MapboxMap? _map;
  MapboxLiveAnnotations? _annotations;
  bool _styleReady = false;
  bool _revealed = false;

  Timer? _syncTimer;
  String _syncSignature = '';

  Timer? _fitTimer;
  DateTime? _lastFitAt;
  List<Point> _pendingFit = const [];
  String? _fitSignature;

  @override
  void didUpdateWidget(covariant _MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleAnnotations();
    _scheduleFit();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _fitTimer?.cancel();
    _annotations?.dispose();
    super.dispose();
  }

  List<Point> get _fitPoints => [
    for (final pin in widget.pins)
      Point(coordinates: Position(pin.longitude, pin.latitude)),
    if (widget.destination case final point?)
      Point(coordinates: Position(point.longitude, point.latitude)),
  ];

  void _onMapCreated(MapboxMap map) {
    _map = map;
  }

  void _onStyleLoaded(StyleLoadedEventData event) {
    _styleReady = true;
    _annotations?.dispose();
    final map = _map;
    if (map == null) return;

    unawaited(MapboxStandardStyle.apply(map, dark: widget.darkMode));

    final annotations = MapboxLiveAnnotations(map);
    annotations.onMemberTapped = widget.onMemberTapped;
    _annotations = annotations;
    unawaited(annotations.initialize());
    _syncSignature = '';
    _scheduleAnnotations(force: true, immediate: true);
    _scheduleFit(force: true);

    if (_fitPoints.isEmpty) {
      setState(() => _revealed = true);
    }
  }

  String _annotationSignature() => [
    for (final pin in widget.pins) pin.signature,
    for (final route in widget.routes) route.signature,
    'dest:${widget.destination?.latitude},${widget.destination?.longitude}',
    'color:${widget.destinationColor.toARGB32()}',
  ].join('|');

  void _scheduleAnnotations({bool force = false, bool immediate = false}) {
    if (!_styleReady) return;
    final signature = _annotationSignature();
    if (!force && signature == _syncSignature) return;
    _syncSignature = signature;

    _syncTimer?.cancel();
    if (immediate) {
      _applyAnnotations();
      return;
    }
    _syncTimer = Timer(const Duration(milliseconds: 400), _applyAnnotations);
  }

  void _applyAnnotations() {
    final annotations = _annotations;
    if (!mounted || annotations == null) return;
    unawaited(
      annotations.sync(
        members: widget.pins,
        routes: widget.routes,
        destination: widget.destination,
        destinationColor: widget.destinationColor,
      ),
    );
  }

  /// Keeps every located member and the shared destination in frame. Fits are
  /// throttled so new GPS fixes do not yank the camera around constantly.
  void _scheduleFit({bool force = false}) {
    if (!_styleReady || _map == null) return;

    final points = _fitPoints;
    if (points.isEmpty) return;

    final signature = points
        .map(
          (point) =>
              '${point.coordinates.lat.toStringAsFixed(3)},'
              '${point.coordinates.lng.toStringAsFixed(3)}',
        )
        .join('|');
    if (!force && signature == _fitSignature) return;

    _fitSignature = signature;
    _pendingFit = List.unmodifiable(points);

    final now = DateTime.now();
    final last = _lastFitAt;
    final elapsed = last == null ? null : now.difference(last);
    final remaining = elapsed == null || elapsed >= _fitInterval
        ? Duration.zero
        : _fitInterval - elapsed;

    _fitTimer?.cancel();
    if (remaining == Duration.zero) {
      unawaited(_fitNow());
    } else {
      _fitTimer = Timer(remaining, () => unawaited(_fitNow()));
    }
  }

  Future<void> _fitNow() async {
    final map = _map;
    if (!mounted || !_styleReady || map == null || _pendingFit.isEmpty) return;
    _lastFitAt = DateTime.now();

    try {
      final camera = await map.cameraForCoordinatesPadding(
        _pendingFit,
        CameraOptions(),
        MbxEdgeInsets(top: 54, left: 48, bottom: 64, right: 48),
        15,
        null,
      );
      if (!mounted) return;
      camera.pitch = MapboxStandardStyle.previewPitch;
      await map.easeTo(camera, MapAnimationOptions(duration: 650));
    } catch (_) {
      // The camera helper rejects while a style swap is in flight.
    }

    if (mounted && !_revealed) {
      setState(() => _revealed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!MapboxConfig.isConfigured) {
      return const _MissingTokenSurface();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: MapWidget(
            key: ValueKey(widget.darkMode),
            styleUri: MapboxStandardStyle.uri,
            viewport: _viewport,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
          ),
        ),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _revealed ? 0 : 1,
            duration: const Duration(milliseconds: 350),
            child: ColoredBox(color: scheme.surfaceContainerHigh),
          ),
        ),
      ],
    );
  }
}

class _MissingTokenSurface extends StatelessWidget {
  const _MissingTokenSurface();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.surfaceContainerHigh, scheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Add a Mapbox token to show the map',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickOnMapButton extends StatelessWidget {
  const _PickOnMapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Pick a destination on the map',
      child: Material(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.94),
        shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              Icons.add_location_alt_outlined,
              size: 15,
              color: scheme.primary,
            ),
          ),
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
    required this.livePoint,
    required this.onTap,
  });

  final bool destinationSet;
  final bool isConfigured;
  final bool hasRoutes;
  final String? error;
  final List<({CircleMember member, MemberRoute route})> routes;
  final Map<String, Color> routeColors;
  final String currentUserId;
  final GeoPoint? livePoint;
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

    final now = DateTime.now();

    String detailFor(CircleMember member, MemberRoute route) {
      final isMe = member.profile.id == currentUserId;
      final current = isMe
          ? (livePoint ?? member.status?.location ?? route.origin)
          : (member.status?.location ?? route.origin);
      final progress = RouteProgress.from(route.plan, current, now: now);
      if (progress.arrived) return 'Arrived';
      return '${formatRouteDistance(progress.remainingMeters)} · '
          '${formatRouteEta(progress.remaining)}';
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
              detail: detailFor(entry.member, entry.route),
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
    required this.detail,
    required this.color,
  });

  final String name;
  final String detail;
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
            '$name $detail',
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
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
