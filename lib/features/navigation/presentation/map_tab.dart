import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart' hide NavigationDestination;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide Size, Visibility;

import '../../../app/navigation/glass_dock.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/application/app_visibility.dart';
import '../../../core/config/mapbox_config.dart';
import '../../chat/application/chat_providers.dart';
import '../../circle/application/circle_providers.dart';
import '../../circle/domain/circle_member.dart';
import '../../location/application/telemetry_providers.dart';
import '../../location/data/last_known_location_store.dart';
import '../../location/domain/device_telemetry.dart';
import '../../location/domain/geo_point.dart';
import '../../location/presentation/widgets/map_circle_view.dart';
import '../../location/presentation/widgets/map_marker_images.dart';
import '../../location/presentation/widgets/mapbox_live_annotations.dart';
import '../../location/presentation/widgets/mapbox_standard_style.dart';
import '../application/destination_draft_providers.dart';
import '../application/map_focus_providers.dart';
import '../application/map_search_providers.dart';
import '../application/navigation_providers.dart';
import '../domain/navigation_destination.dart';
import '../domain/navigation_failure.dart';
import '../domain/place_suggestion.dart';
import '../domain/route_geometry.dart';
import 'venue_selection.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/trip_cockpit.dart';

const _fallbackCenter = GeoPoint(latitude: 8.999, longitude: 38.775);

/// Opening the map starts high and settles onto the member, the way Google
/// Maps does, instead of snapping straight to street level.
const _flyInZoom = 16.2;
const _flyInPitch = 25.0;
const _flyInDurationMs = 1800;
const _startupZoom = 13.8;
const _resumeFixGrace = Duration(milliseconds: 1500);

/// Active-trip cockpit camera. The map sits close, tilted and rotated to the
/// direction of travel, with the member low on screen and the road ahead
/// filling the frame.
const _tripZoom = 17.5;
const _tripPitch = 50.0;
const _restoreZoom = 15.5;
const _tripAnimationMs = 900;
const _tripLeadMeters = 90.0;
const _tripMinMoveMeters = 5.0;
const _tripMinBearingChange = 3.0;
const _tripMinInterval = Duration(milliseconds: 1200);

/// A finger must travel this far across the map before a touch counts as a
/// pan; taps and pinch starts should not stop the tracking camera.
const _tripDragSlop = 8.0;

/// Matches the maneuver banner (top) and summary bar (bottom) so the member's
/// pin lands in the lower third with the road ahead visible.
final _tripPadding = MbxEdgeInsets(top: 128, left: 0, bottom: 210, right: 0);

/// Whether the native Mapbox widget may be mounted.
///
/// Mapbox renders into a native surface on Android. Keeping that surface alive
/// while its tab is offstage lets it reappear above the active tab after the
/// app resumes, so it is only mounted while it can actually be seen.
@visibleForTesting
bool shouldMountNativeMap({
  required bool tabActive,
  required bool foreground,
  required bool configured,
}) => configured && tabActive && foreground;

/// The live Mapbox tab: member pins, routes, destination picking and the
/// arrival HUD.
///
/// A tap first looks for a named POI or extruded building under the finger.
/// When one is found the camera tilts onto it and the card shows the venue's
/// name, category and address. Taps on empty map drop a plain pin that stays
/// glued to the middle of the map, so dragging is how you fine-tune it.
///
/// The shell keeps this widget mounted across tab switches so the draft, camera
/// and search state survive. The native surface is a different matter: SurfaceView
/// punches through Flutter's canvas on Android resume, so the Mapbox widget is
/// mounted only while this tab is active and the app is in the foreground.
class MapTab extends ConsumerStatefulWidget {
  const MapTab({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.members,
    required this.onMemberTap,
    required this.onChat,
    required this.active,
  });

  final String circleId;
  final String currentUserId;
  final List<CircleMember> members;
  final ValueChanged<CircleMember> onMemberTap;

  /// Opens the chat tab, which owns shared locations now.
  final VoidCallback onChat;

  /// Whether the map is the selected tab. When false the native view is
  /// detached so it cannot render over the active tab after a resume.
  final bool active;

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  late final GeoPoint _initialCenter;
  late CameraViewportState _viewport;
  late AppVisibility _appVisibility;

  MapboxMap? _map;
  MapboxLiveAnnotations? _annotations;
  PointAnnotationManager? _venueHighlights;
  FeaturesetFeature? _selectedBuilding;
  VenueHit? _selectedVenue;
  List<CircleMember>? _mapMembers;
  Timer? _annotationTimer;
  bool _styleReady = false;
  bool _mapAttached = false;
  bool _foreground = true;
  bool _moving = false;
  bool _seeded = false;
  bool _saving = false;
  bool _querying = false;
  bool _venueFlight = false;
  bool _searchSelection = false;
  bool _centerFlight = false;
  bool _programmaticCamera = false;
  bool _initialCameraFlightDone = false;
  bool _initialFlightPending = false;
  bool _resumeRefocus = false;
  bool _tripPaused = false;
  double? _trackBearing;
  GeoPoint? _trackedPoint;
  DateTime? _lastTrackedAt;
  Offset? _touchStart;
  GeoPoint? _pendingUserCenter;
  MapFocusRequest? _pendingFocus;
  int _appliedFocusRevision = 0;
  String? _error;

  /// The last camera the member saw. It is restored when the native map is
  /// remounted, so switching tabs does not lose their place.
  Point _cameraCenter = Point(
    coordinates: Position(_fallbackCenter.longitude, _fallbackCenter.latitude),
  );
  double _cameraZoom = _startupZoom;
  double _cameraBearing = 0;
  double _cameraPitch = 0;
  int _idleRun = 0;
  int _styleGeneration = 0;

  @override
  void initState() {
    super.initState();
    _initialCenter = _resolveInitialCenter();
    _cameraCenter = Point(
      coordinates: Position(_initialCenter.longitude, _initialCenter.latitude),
    );
    _viewport = _buildViewport();
    _appVisibility = ref.read(appVisibilityProvider);
    _foreground = _appVisibility.isForeground;
    _appVisibility.addListener(_onVisibilityChanged);
    // A request raised before this tab existed is stale.
    _appliedFocusRevision = ref.read(mapFocusControllerProvider)?.revision ?? 0;
  }

  /// Opening the app lands on the member's own fix, so the map is useful
  /// before they touch anything. A destination entered later wins the camera.
  GeoPoint _resolveInitialCenter() {
    final reading = ref
        .read(telemetryControllerProvider(widget.currentUserId))
        .lastReading;
    if (reading != null) return reading.point;

    // The local cache outlives the process; the last fix in this session does
    // not, so a cold start would otherwise wait for a satellite lock.
    final cached = ref.read(lastKnownLocationStoreProvider).read();
    if (cached != null) return cached;

    final ownStatus = _ownStatusPoint();
    if (ownStatus != null) return ownStatus;

    final destination = ref
        .read(navigationControllerProvider(widget.circleId))
        .destination;
    return destination?.point ?? _fallbackCenter;
  }

  GeoPoint? _ownStatusPoint() {
    for (final member in _currentMembers) {
      if (member.profile.id == widget.currentUserId) {
        return member.status?.location;
      }
    }
    return null;
  }

  CameraViewportState _buildViewport() {
    final trip =
        ref.read(navigationControllerProvider(widget.circleId)).destination !=
        null;
    return CameraViewportState(
      center: _cameraCenter,
      padding: trip ? const EdgeInsets.only(top: 128, bottom: 210) : null,
      zoom: _cameraZoom,
      bearing: _cameraBearing,
      pitch: _cameraPitch,
    );
  }

  void _onVisibilityChanged() {
    if (!mounted) return;
    final foreground = _appVisibility.isForeground;
    if (foreground == _foreground) return;

    if (foreground) {
      // Returning is a new map session: fly to where the member is now
      // instead of restoring the camera they left behind.
      _initialCameraFlightDone = false;
      _initialFlightPending = false;
      _resumeRefocus = true;
      _pendingUserCenter = null;
      _tripPaused = false;
      _trackBearing = null;
      _trackedPoint = null;
      _lastTrackedAt = null;
      _touchStart = null;
    }
    setState(() => _foreground = foreground);

    if (foreground) {
      // The native map can keep its style across a pause, so the style-loaded
      // callback may never fire; start the resume flight on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_performInitialFlight());
      });
    }
  }

  /// Attaches the native view at the camera position the member last saw.
  void _attachNativeMap() {
    _mapAttached = true;
    _viewport = _buildViewport();
  }

  /// Drops every handle into the native map before Flutter removes the view.
  ///
  /// Leaving those handles behind would let a disused MapboxMap receive
  /// annotation or camera calls while a new one is being created.
  void _detachNativeMap() {
    _mapAttached = false;
    _styleReady = false;
    _styleGeneration++;
    _annotationTimer?.cancel();
    _annotationTimer = null;
    _annotations?.dispose();
    _annotations = null;
    _venueHighlights = null;
    _selectedBuilding = null;
    _venueFlight = false;
    _centerFlight = false;
    _programmaticCamera = false;
    _initialFlightPending = false;
    _resumeRefocus = false;
    _tripPaused = false;
    _trackBearing = null;
    _trackedPoint = null;
    _lastTrackedAt = null;
    _touchStart = null;
    _map = null;
    _moving = false;
  }

  @override
  void dispose() {
    _appVisibility.removeListener(_onVisibilityChanged);
    _annotationTimer?.cancel();
    _annotations?.dispose();
    super.dispose();
  }

  void _seedDraft(NavigationDestination? destination) {
    if (!mounted) return;
    final provider = destinationDraftControllerProvider(widget.circleId);
    if (ref.read(provider).hasPoint) return;

    final controller = ref.read(provider.notifier);
    if (destination != null) {
      controller.seed(destination);
      return;
    }

    final reading = ref
        .read(telemetryControllerProvider(widget.currentUserId))
        .lastReading;
    if (reading != null) {
      controller.select(reading.point.latitude, reading.point.longitude);
    }
  }

  /// A first fix can land after the map is already showing the fallback area.
  /// The entrance flight runs at most once per map session; later ticks must
  /// never pull the camera away from where the member is looking.
  void _onUserReading(DeviceReading? reading) {
    if (!mounted || reading == null) return;
    unawaited(_rememberPosition(reading.point));

    if (ref.read(navigationControllerProvider(widget.circleId)).destination !=
        null) {
      unawaited(_updateTripCamera());
    }

    if (_initialCameraFlightDone) return;

    if (ref.read(destinationDraftControllerProvider(widget.circleId)).isVenue) {
      // A place chosen before the fix landed already owns the camera.
      _initialCameraFlightDone = true;
      return;
    }
    if (_map == null || !_styleReady || !_mapAttached) {
      _pendingUserCenter = reading.point;
      return;
    }
    // A streamed reading is current by definition, so the resume grace that
    // asks for a one-shot fix is not needed here.
    _resumeRefocus = false;
    unawaited(_performInitialFlight(target: reading.point));
  }

  /// Keeps the local cache fresh even after the entrance flight has run, so
  /// the next cold start has somewhere to go before the first GPS lock.
  Future<void> _rememberPosition(GeoPoint point) async {
    final store = ref.read(lastKnownLocationStoreProvider);
    final cached = store.read();
    if (cached != null && distanceMeters(cached, point) < 10) return;
    try {
      await store.write(point);
    } catch (_) {
      // The cache is a convenience; it must never block the map.
    }
  }

  /// The Google-Maps-style entrance: start high and settle onto the member, or
  /// frame them together with the shared destination when a trip is running.
  Future<void> _performInitialFlight({GeoPoint? target}) async {
    if (_initialCameraFlightDone || _initialFlightPending || !mounted) return;

    _initialFlightPending = true;
    try {
      var point =
          target ??
          _pendingUserCenter ??
          ref
              .read(telemetryControllerProvider(widget.currentUserId))
              .lastReading
              ?.point ??
          ref.read(lastKnownLocationStoreProvider).read();

      if (_resumeRefocus) {
        _resumeRefocus = false;
        // Coming back after a drive needs a fresh fix; the cached point is
        // where they were before the trip, which reads as a random location.
        final fresh = await ref
            .read(deviceTelemetrySourceProvider)
            .currentReading()
            .timeout(_resumeFixGrace, onTimeout: () => null);
        if (!mounted) return;
        point = fresh?.point ?? point;
      }

      if (point == null) return;

      final map = _map;
      if (map == null || !_styleReady || !_mapAttached) {
        _pendingUserCenter = point;
        return;
      }

      _pendingUserCenter = null;
      // Committed: telemetry ticks from here on must not hijack the camera.
      _initialCameraFlightDone = true;

      final destination = ref
          .read(navigationControllerProvider(widget.circleId))
          .destination;
      if (destination == null) {
        await _flyToUser(point);
      } else {
        _tripPaused = false;
        await _flyIntoTrip(point);
      }
    } finally {
      _initialFlightPending = false;
    }
  }

  Future<void> _flyToUser(GeoPoint point) async {
    final map = _map;
    if (map == null || !_styleReady) return;

    _centerFlight = true;
    _programmaticCamera = true;
    try {
      await _flyCameraToUser(map, point);
    } finally {
      _programmaticCamera = false;
    }

    if (!mounted) return;
    final hasDestination = ref
        .read(navigationControllerProvider(widget.circleId))
        .destination;
    final draft = ref.read(destinationDraftControllerProvider(widget.circleId));
    // The camera now sits on the fix, so an empty picker should start there.
    if (hasDestination == null && !draft.hasPoint) {
      _select(point.longitude, point.latitude);
    }
  }

  /// Enters the tilted navigation perspective and lets tracking take over.
  ///
  /// Runs before the first Directions response too, so the cockpit does not
  /// wait on the network to start looking like a navigation screen.
  Future<void> _flyIntoTrip(GeoPoint point) async {
    final map = _map;
    if (map == null || !_styleReady || !mounted) return;

    final route = ref
        .read(navigationControllerProvider(widget.circleId))
        .routeFor(widget.currentUserId);
    final lead = route == null
        ? point
        : pointAheadOnLine(point, route.plan.geometry, _tripLeadMeters) ??
              point;
    final bearing = distanceMeters(point, lead) > 2
        ? bearingBetween(point, lead)
        : (_trackBearing ?? 0.0);

    _trackBearing = bearing;
    _trackedPoint = point;
    _lastTrackedAt = DateTime.now();
    _centerFlight = true;
    _programmaticCamera = true;
    _setMoving(true);
    try {
      await map.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(lead.longitude, lead.latitude)),
          padding: _tripPadding,
          zoom: _tripZoom,
          pitch: _tripPitch,
          bearing: bearing,
        ),
        MapAnimationOptions(duration: _flyInDurationMs),
      );
    } catch (_) {
      // A style swap can reject the camera mid-flight.
    } finally {
      _programmaticCamera = false;
      _setMoving(false);
    }
  }

  /// Keeps the cockpit camera glued to the member as fixes land.
  ///
  /// Updates are throttled so a burst of fixes does not restart the animation
  /// before the previous one settles, and the bearing is eased toward the new
  /// heading instead of being snapped, which is what makes turns feel smooth.
  Future<void> _updateTripCamera({bool force = false}) async {
    // Never stack a tracking move on top of the entrance flight.
    if (!mounted || _tripPaused || _programmaticCamera) return;
    final map = _map;
    if (map == null || !_styleReady || !_mapAttached) return;

    final navigation = ref.read(navigationControllerProvider(widget.circleId));
    if (navigation.destination == null) return;
    final route = navigation.routeFor(widget.currentUserId);
    final reading = ref
        .read(telemetryControllerProvider(widget.currentUserId))
        .lastReading;
    final point = reading?.point ?? route?.origin;
    if (route == null || point == null) return;

    final lead =
        pointAheadOnLine(point, route.plan.geometry, _tripLeadMeters) ?? point;
    final target = _tripBearingFor(reading, point, lead);
    final bearing = _trackBearing == null
        ? target
        : lerpBearing(_trackBearing!, target, force ? 0.6 : 0.35);

    final now = DateTime.now();
    final last = _lastTrackedAt;
    final previous = _trackedPoint;
    final moved = previous == null
        ? double.infinity
        : distanceMeters(previous, point);
    final turned = _trackBearing == null
        ? 180.0
        : _bearingGap(_trackBearing!, bearing);
    if (!force &&
        last != null &&
        now.difference(last) < _tripMinInterval &&
        moved < _tripMinMoveMeters &&
        turned < _tripMinBearingChange) {
      return;
    }

    _trackBearing = bearing;
    _trackedPoint = point;
    _lastTrackedAt = now;
    _programmaticCamera = true;
    try {
      await map.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(lead.longitude, lead.latitude)),
          padding: _tripPadding,
          zoom: _tripZoom,
          pitch: _tripPitch,
          bearing: bearing,
        ),
        MapAnimationOptions(duration: _tripAnimationMs),
      );
    } catch (_) {
      // Best effort; the next fix retries.
    } finally {
      _programmaticCamera = false;
    }
  }

  /// GPS heading while moving; otherwise the direction the member actually
  /// travelled, then the route itself. Standing still must not spin the map.
  double _tripBearingFor(
    DeviceReading? reading,
    GeoPoint point,
    GeoPoint lead,
  ) {
    final heading = reading?.headingDegrees;
    if (heading != null && (reading?.speedKph ?? 0) >= 2) return heading;

    final previous = _trackedPoint;
    if (previous != null && distanceMeters(previous, point) >= 3) {
      return bearingBetween(previous, point);
    }
    return distanceMeters(point, lead) > 2 ? bearingBetween(point, lead) : 0;
  }

  static double _bearingGap(double from, double to) {
    final delta = (to - from) % 360;
    return delta > 180 ? 360 - delta : delta;
  }

  /// Snaps back to the tracking perspective after the member pans away.
  void _recenterTrip() {
    _touchStart = null;
    setState(() => _tripPaused = false);
    _trackBearing = null;
    _trackedPoint = null;
    _lastTrackedAt = null;
    unawaited(_updateTripCamera(force: true));
  }

  /// Returns to the plain overhead map once the trip is over.
  Future<void> _leaveTripCamera() async {
    _tripPaused = false;
    _trackBearing = null;
    _trackedPoint = null;
    _lastTrackedAt = null;
    _touchStart = null;

    final map = _map;
    if (map == null || !_styleReady || !mounted) return;

    final reading = ref
        .read(telemetryControllerProvider(widget.currentUserId))
        .lastReading;
    final target = reading?.point ?? _ownStatusPoint();
    final center = target == null
        ? _cameraCenter
        : Point(coordinates: Position(target.longitude, target.latitude));

    _centerFlight = true;
    _programmaticCamera = true;
    _setMoving(true);
    try {
      await map.easeTo(
        CameraOptions(center: center, zoom: _restoreZoom, bearing: 0, pitch: 0),
        MapAnimationOptions(duration: 1200),
      );
    } catch (_) {
      // The next entrance flight will correct it.
    } finally {
      _programmaticCamera = false;
      _setMoving(false);
    }
  }

  /// The shared camera move used by the entrance flight and the locate
  /// button, so both feel identical.
  Future<void> _flyCameraToUser(MapboxMap map, GeoPoint point) async {
    _setMoving(true);
    try {
      await map.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(point.longitude, point.latitude)),
          zoom: _flyInZoom,
          pitch: _flyInPitch,
          bearing: 0.0,
        ),
        MapAnimationOptions(duration: _flyInDurationMs),
      );
    } catch (_) {
      // A style swap can reject the camera mid-flight.
      _centerFlight = false;
    } finally {
      _setMoving(false);
    }
  }

  static String _destinationKey(NavigationDestination destination) =>
      '${destination.latitude},${destination.longitude}';

  /// True while the picker still holds the shared destination, as opposed to a
  /// new point the member is positioning under the centre pin.
  static bool _draftIsDestination(
    DestinationDraft draft,
    NavigationDestination? destination,
  ) {
    if (destination == null || !draft.hasPoint) return false;
    return distanceMeters(
          GeoPoint(latitude: draft.latitude!, longitude: draft.longitude!),
          destination.point,
        ) <=
        1;
  }

  /// A new destination starts the cockpit; clearing it returns the map to the
  /// plain overhead view.
  void _onDestinationChanged(
    NavigationDestination? previous,
    NavigationDestination? next,
  ) {
    if (next == null) {
      final wasActive = previous != null;
      _tripPaused = false;
      _trackBearing = null;
      _trackedPoint = null;
      _lastTrackedAt = null;
      _touchStart = null;
      _pendingUserCenter = null;
      if (wasActive) unawaited(_leaveTripCamera());
      return;
    }

    final key = _destinationKey(next);
    final previousKey = previous == null ? null : _destinationKey(previous);
    if (key == previousKey) return;

    _tripPaused = false;
    _trackBearing = null;
    _trackedPoint = null;
    _lastTrackedAt = null;
    _touchStart = null;
    _pendingUserCenter = null;
    // Let the entrance flight drive the angled camera for the new trip.
    _initialCameraFlightDone = false;
    _initialFlightPending = false;
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_performInitialFlight());
    });
  }

  void _onMapCreated(MapboxMap map) {
    if (!mounted || !_mapAttached) return;
    _map = map;
    map.addInteraction(
      TapInteraction.onMap(_handleMapTap),
      interactionID: 'picker-tap',
    );
    if (!kIsWeb) {
      map.addInteraction(
        LongTapInteraction.onMap(_handleMapTap),
        interactionID: 'picker-long-tap',
      );
    }
  }

  Future<void> _handleMapTap(MapContentGestureContext context) async {
    if (_querying) return;
    // The picker is closed during a trip; the summary bar owns the exit.
    if (ref.read(navigationControllerProvider(widget.circleId)).destination !=
        null) {
      return;
    }

    final longitude = context.point.coordinates.lng.toDouble();
    final latitude = context.point.coordinates.lat.toDouble();
    final map = _map;

    if (map == null) {
      _selectFallback(longitude, latitude);
      return;
    }

    _querying = true;
    try {
      final venue = await venueAt(map, context.touchPosition, context.point);
      if (!mounted) return;
      if (venue != null) {
        _selectVenue(venue);
      } else {
        _selectFallback(longitude, latitude);
      }
    } finally {
      _querying = false;
    }
  }

  void _selectFallback(double longitude, double latitude) {
    _clearVenueSelection();
    _select(longitude, latitude);
    unawaited(_easeTo(longitude, latitude));
  }

  void _selectVenue(VenueHit venue) {
    _searchSelection = false;
    _selectedVenue = venue;
    ref
        .read(destinationDraftControllerProvider(widget.circleId).notifier)
        .selectVenue(
          latitude: venue.point.latitude,
          longitude: venue.point.longitude,
          name: venue.name,
          category: venue.categoryLabel,
          maki: venue.maki,
        );
    unawaited(_highlightBuilding(venue));
    unawaited(_drawVenueHighlight(venue));
    unawaited(_flyToVenue(venue.point));
  }

  /// Handles a Mapbox autocomplete result: the address is already known, so
  /// no reverse geocode is needed before the venue card opens.
  void _selectSuggestion(PlaceSuggestion place) {
    _showSearchVenue(
      point: GeoPoint(latitude: place.latitude, longitude: place.longitude),
      name: place.displayName,
      address: place.address,
      category: place.categoryLabel,
      maki: place.maki,
    );
  }

  /// Jumps to a place shared in the chat thread.
  void _showSharedLocation(GeoPoint point, String? label) {
    final name = label?.trim();
    _showSearchVenue(
      point: point,
      name: name == null || name.isEmpty ? 'Shared location' : name,
    );
  }

  void _showSearchVenue({
    required GeoPoint point,
    required String name,
    String? address,
    String? category,
    String? maki,
  }) {
    _searchSelection = true;
    final venue = VenueHit(
      point: point,
      name: name,
      category: category,
      maki: maki,
    );
    _selectedVenue = venue;
    ref
        .read(destinationDraftControllerProvider(widget.circleId).notifier)
        .selectVenue(
          latitude: point.latitude,
          longitude: point.longitude,
          name: name,
          address: address,
          category: category,
          maki: maki,
        );
    unawaited(_highlightBuilding(null));
    unawaited(_drawVenueHighlight(venue, pin: true));
    unawaited(_flyToVenue(point));
  }

  void _openChat() {
    FocusScope.of(context).unfocus();
    ref
        .read(mapSearchControllerProvider(widget.currentUserId).notifier)
        .dismiss();
    widget.onChat();
  }

  void _onFocusRequested(MapFocusRequest? request) {
    if (request == null) return;
    _pendingFocus = request;
    _applyPendingFocus();
  }

  void _applyPendingFocus() {
    final focus = _pendingFocus;
    if (focus == null || !_styleReady) return;
    _pendingFocus = null;
    if (focus.revision <= _appliedFocusRevision) return;
    _appliedFocusRevision = focus.revision;
    _showSharedLocation(focus.point, focus.label);
  }

  void _clearVenueSelection() {
    _searchSelection = false;
    if (_selectedVenue == null && _selectedBuilding == null) return;
    _selectedVenue = null;
    unawaited(_highlightBuilding(null));
    unawaited(_drawVenueHighlight(null));
  }

  Future<void> _highlightBuilding(VenueHit? venue) async {
    final map = _map;
    if (map == null) return;

    final next = venue?.isBuilding == true ? venue!.feature : null;
    final previous = _selectedBuilding;
    if (previous == next) return;
    _selectedBuilding = next;

    await _setBuildingSelected(map, previous, false);
    await _setBuildingSelected(map, next, true);
  }

  Future<void> _setBuildingSelected(
    MapboxMap map,
    FeaturesetFeature? feature,
    bool selected,
  ) async {
    if (feature == null) return;
    try {
      await map.setFeatureStateForFeaturesetFeature(
        feature,
        StandardBuildingsState(select: selected),
      );
    } catch (_) {
      // Feature state needs a feature id and a settled Standard style.
    }
  }

  Future<void> _drawVenueHighlight(VenueHit? venue, {bool pin = false}) async {
    final manager = _venueHighlights;
    if (manager == null) return;

    try {
      await manager.deleteAll();
      if (venue == null || !mounted) return;
      final color = Theme.of(context).colorScheme.tertiary;
      final image = pin
          ? await MapMarkerImages.destination(color: color)
          : await MapMarkerImages.venueHighlight(color: color);
      if (!mounted) return;
      await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(venue.point.longitude, venue.point.latitude),
          ),
          image: image,
          iconSize: pin ? 0.5 : 0.48,
          iconAnchor: pin ? IconAnchor.BOTTOM : IconAnchor.CENTER,
        ),
      );
    } catch (_) {
      // Annotation managers are unimplemented on web.
    }
  }

  Future<void> _flyToVenue(GeoPoint point) async {
    final map = _map;
    if (map == null) return;

    _venueFlight = true;
    _setMoving(true);
    try {
      await map.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(point.longitude, point.latitude)),
          zoom: _cameraZoom < 16.2 ? 16.2 : _cameraZoom,
          pitch: MapboxStandardStyle.venuePitch,
        ),
        MapAnimationOptions(duration: 1100),
      );
    } catch (_) {
      // Camera animations are best effort, but a failed flight must not swallow
      // the next idle event.
      _venueFlight = false;
    }
    _setMoving(false);
  }

  void _select(double longitude, double latitude, {String? label}) {
    ref
        .read(destinationDraftControllerProvider(widget.circleId).notifier)
        .select(latitude, longitude, label: label);
  }

  void _onCameraChanged(CameraChangedEventData event) {
    final camera = event.cameraState;
    _cameraCenter = camera.center;
    _cameraZoom = camera.zoom;
    _cameraBearing = camera.bearing;
    _cameraPitch = camera.pitch;

    if (_programmaticCamera) return;

    if (ref.read(navigationControllerProvider(widget.circleId)).destination ==
        null) {
      // Any camera the app did not drive is the member taking over: the
      // entrance-flight flag must stop.
      _centerFlight = false;
      _setMoving(true);
    }
    // During a trip every camera move we did not command is either an
    // animation frame or a drag. Only a real touch pauses tracking (see
    // [_onPointerMove]) so trailing frames cannot fake a gesture.
  }

  void _onPointerDown(PointerDownEvent event) {
    if (ref.read(navigationControllerProvider(widget.circleId)).destination ==
        null) {
      return;
    }
    _touchStart = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final start = _touchStart;
    if (start == null || _tripPaused) return;
    if ((event.position - start).distance < _tripDragSlop) return;

    _touchStart = null;
    setState(() => _tripPaused = true);
  }

  void _onPointerRelease(PointerEvent event) {
    _touchStart = null;
  }

  void _onStyleLoaded(StyleLoadedEventData event) {
    if (!mounted || !_mapAttached) return;
    _styleReady = true;
    _annotations?.dispose();
    final map = _map;
    if (map == null) return;

    unawaited(
      MapboxStandardStyle.apply(
        map,
        dark: Theme.of(context).brightness == Brightness.dark,
      ),
    );

    final annotations = MapboxLiveAnnotations(map, iconScale: 0.5);
    annotations.onMemberTapped = (memberId) {
      for (final member in _currentMembers) {
        if (member.profile.id == memberId) {
          widget.onMemberTap(member);
          return;
        }
      }
    };
    _annotations = annotations;
    unawaited(annotations.initialize());
    _syncAnnotations();

    _selectedBuilding = null;
    unawaited(_restoreVenueHighlight(map));
    _applyPendingFocus();

    unawaited(_performInitialFlight());
  }

  Future<void> _restoreVenueHighlight(MapboxMap map) async {
    final generation = ++_styleGeneration;
    try {
      final manager = await map.annotations.createPointAnnotationManager(
        id: 'venue-highlight-$generation',
      );
      await manager.setIconAllowOverlap(true);
      if (!mounted || !_mapAttached || generation != _styleGeneration) return;
      _venueHighlights = manager;

      final venue = _selectedVenue;
      if (venue != null) {
        await _highlightBuilding(venue);
        await _drawVenueHighlight(venue, pin: _searchSelection);
      }
    } catch (_) {
      // Web has no annotation managers; the venue card still drives selection.
    }
  }

  void _syncAnnotations() {
    final annotations = _annotations;
    if (!_styleReady || !_mapAttached || annotations == null || !mounted) {
      return;
    }

    final navigation = ref.read(navigationControllerProvider(widget.circleId));
    final destination = navigation.destination;
    final view = MapCircleView.from(
      members: _currentMembers,
      currentUserId: widget.currentUserId,
      navigation: navigation,
      scheme: Theme.of(context).colorScheme,
    );

    unawaited(
      annotations.sync(
        members: view.pins,
        routes: view.lines,
        destination: destination?.point,
        destinationColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  List<CircleMember> get _currentMembers => _mapMembers ?? widget.members;

  /// Routes and peer fixes arrive while the picker is open, so redraw the
  /// annotations rather than only painting them once per style load.
  void _scheduleSync() {
    if (!_styleReady || !_mapAttached) return;
    _annotationTimer?.cancel();
    _annotationTimer = Timer(
      const Duration(milliseconds: 350),
      _syncAnnotations,
    );
  }

  void _setMoving(bool moving) {
    if (!mounted || _moving == moving) return;
    setState(() => _moving = moving);
  }

  Future<void> _easeTo(double longitude, double latitude) async {
    final map = _map;
    if (map == null) return;
    _setMoving(true);

    try {
      await map.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: _cameraZoom,
          pitch: MapboxStandardStyle.pickerPitch,
        ),
        MapAnimationOptions(duration: 450),
      );
    } catch (_) {
      // A style swap can reject the camera mid-flight.
    }
    _setMoving(false);
  }

  Future<void> _handleIdle() async {
    final map = _map;
    if (map == null || !mounted || !_mapAttached) return;

    final run = ++_idleRun;
    try {
      final camera = await map.getCameraState();
      if (!mounted || !_mapAttached || run != _idleRun) return;

      _cameraCenter = camera.center;
      _cameraZoom = camera.zoom;
      _cameraBearing = camera.bearing;
      _cameraPitch = camera.pitch;
      _setMoving(false);

      // The picker is closed during a trip, so camera idle never moves the
      // draft; the cockpit owns the screen.
      if (ref.read(navigationControllerProvider(widget.circleId)).destination !=
          null) {
        return;
      }

      // The first idle after a venue flight is the camera arriving at a point
      // the draft already holds, so it must not be treated as a pan.
      if (_venueFlight) {
        _venueFlight = false;
        return;
      }

      // The idles after the launch centring sit on cameras the member did not
      // choose, so they must not move the draft. The flag stays set until a
      // real camera change clears it.
      if (_centerFlight) return;

      final latitude = camera.center.coordinates.lat.toDouble();
      final longitude = camera.center.coordinates.lng.toDouble();
      final draft = ref.read(
        destinationDraftControllerProvider(widget.circleId),
      );
      final drifted =
          !draft.hasPoint ||
          distanceMeters(
                GeoPoint(
                  latitude: draft.latitude!,
                  longitude: draft.longitude!,
                ),
                GeoPoint(latitude: latitude, longitude: longitude),
              ) >
              4;

      if (drifted) {
        _clearVenueSelection();
        _select(longitude, latitude);
      }
    } catch (_) {
      // Ignore a camera read that raced a style reload.
    }
  }

  Future<void> _goToMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    var reading = ref
        .read(telemetryControllerProvider(widget.currentUserId))
        .lastReading;

    if (reading == null) {
      await ref
          .read(telemetryControllerProvider(widget.currentUserId).notifier)
          .requestAccess();
      if (!mounted) return;
      reading = ref
          .read(telemetryControllerProvider(widget.currentUserId))
          .lastReading;
    }

    if (reading == null) {
      // A cold start can still know where the member was; the locate button
      // should take them there rather than refusing to move.
      final cached = ref.read(lastKnownLocationStoreProvider).read();
      final map = _map;
      if (cached == null || map == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Waiting for a location fix…')),
        );
        return;
      }
      await _flyCameraToUser(map, cached);
      return;
    }

    final map = _map;
    if (map == null) return;
    await _flyCameraToUser(map, reading.point);
  }

  Future<void> _confirm() async {
    final draft = ref.read(destinationDraftControllerProvider(widget.circleId));
    final point = draft.point;
    if (point == null || _saving) return;

    final label = draft.label?.trim().isNotEmpty == true
        ? draft.label!.trim()
        : draft.coordinates;

    setState(() {
      _saving = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(navigationRepositoryProvider(widget.circleId))
          .setDestination(
            label: label,
            latitude: point.latitude,
            longitude: point.longitude,
            setBy: widget.currentUserId,
          );
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Everyone is heading to $label.')),
      );
    } on NavigationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _endNavigation() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(navigationRepositoryProvider(widget.circleId))
          .clearDestination();
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Navigation ended.')),
      );
    } on NavigationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navigation = ref.watch(navigationControllerProvider(widget.circleId));
    final snapshotMembers = ref
        .watch(circleSnapshotProvider(widget.currentUserId))
        .value
        ?.members;
    final members = snapshotMembers ?? widget.members;
    _mapMembers = members;

    ref.listen(navigationControllerProvider(widget.circleId), (previous, next) {
      _onDestinationChanged(previous?.destination, next.destination);
      _scheduleSync();
      if (next.destination != null) unawaited(_updateTripCamera());
    });
    ref.listen(
      circleSnapshotProvider(widget.currentUserId),
      (_, _) => _scheduleSync(),
    );
    ref.listen(
      telemetryControllerProvider(widget.currentUserId)
          .select((state) => state.lastReading),
      (_, next) => _onUserReading(next),
    );
    ref.listen(
      mapFocusControllerProvider,
      (_, next) => _onFocusRequested(next),
    );

    final draft = ref.watch(
      destinationDraftControllerProvider(widget.circleId),
    );
    final unread = ref.watch(
      chatUnreadCountProvider((
        circleId: widget.circleId,
        userId: widget.currentUserId,
      )),
    );

    if (!_seeded) {
      _seeded = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _seedDraft(navigation.destination),
      );
    }

    final configured = MapboxConfig.isConfigured;
    final tripActive = navigation.destination != null;
    // Offstage native views still own a window surface on Android, and it can
    // reappear above the active tab after the app resumes. Only keep the
    // Mapbox widget mounted while the map is actually on screen.
    final showNativeMap = shouldMountNativeMap(
      tabActive: widget.active,
      foreground: _foreground,
      configured: configured,
    );
    if (showNativeMap && !_mapAttached) {
      _attachNativeMap();
    } else if (!showNativeMap && _mapAttached) {
      _detachNativeMap();
    }

    return TickerMode(
      enabled: widget.active,
      child: Visibility(
        visible: widget.active,
        maintainState: true,
        maintainAnimation: false,
        maintainSize: false,
        child: ColoredBox(
          color: scheme.surface,
          child: Stack(
            children: [
              Positioned.fill(
                child: !configured
                    ? const _MissingMapToken()
                    : showNativeMap
                    ? Listener(
                        onPointerDown: _onPointerDown,
                        onPointerMove: _onPointerMove,
                        onPointerUp: _onPointerRelease,
                        onPointerCancel: _onPointerRelease,
                        child: MapWidget(
                          styleUri: MapboxStandardStyle.uri,
                          viewport: _viewport,
                          // A TextureView is composited inside the Flutter
                          // view, so it respects tab and route z-order.
                          // SurfaceView punches through Flutter's canvas on
                          // Android.
                          textureView:
                              !kIsWeb &&
                              defaultTargetPlatform == TargetPlatform.android,
                          onMapCreated: _onMapCreated,
                          onStyleLoadedListener: _onStyleLoaded,
                          onCameraChangeListener: _onCameraChanged,
                          onMapIdleListener: (_) => unawaited(_handleIdle()),
                        ),
                      )
                    // Mounted while the tab is hidden or the app is in the
                    // background; never painted because the tab is offstage.
                    : const ColoredBox(color: Colors.transparent),
              ),
              if (configured &&
                  draft.hasPoint &&
                  !draft.isVenue &&
                  !_draftIsDestination(draft, navigation.destination))
                Positioned.fill(
                  child: _CenterPin(moving: _moving, color: scheme.tertiary),
                ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 12,
                right: 12,
                child: IgnorePointer(
                  ignoring: tripActive,
                  child: AnimatedOpacity(
                    opacity: tripActive ? 0 : 1,
                    duration: const Duration(milliseconds: 220),
                    child: MapSearchBar(
                      userId: widget.currentUserId,
                      unreadCount: unread,
                      onChat: _openChat,
                      onPlaceSelected: _selectSuggestion,
                    ),
                  ),
                ),
              ),
              if (tripActive)
                Positioned.fill(
                  child: TripCockpit(
                    circleId: widget.circleId,
                    currentUserId: widget.currentUserId,
                    members: members,
                    onChat: _openChat,
                    unreadChats: unread,
                  ),
                ),
              if (tripActive && _tripPaused)
                Positioned(
                  right: 16,
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 160,
                  child: _RecenterButton(onTap: _recenterTrip),
                ),
              if (!tripActive)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: ShellDock.contentInset(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (configured)
                        _LocateButton(
                          onTap: () => unawaited(_goToMyLocation()),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      _SelectionSheet(
                        draft: draft,
                        configured: configured,
                        saving: _saving,
                        error: _error,
                        hasActiveDestination: false,
                        onConfirm: _confirm,
                        onEnd: _endNavigation,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSheet extends StatelessWidget {
  const _SelectionSheet({
    required this.draft,
    required this.configured,
    required this.saving,
    required this.error,
    required this.hasActiveDestination,
    required this.onConfirm,
    required this.onEnd,
  });

  final DestinationDraft draft;
  final bool configured;
  final bool saving;
  final String? error;
  final bool hasActiveDestination;
  final VoidCallback onConfirm;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canConfirm = configured && draft.hasPoint && !saving;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.tertiaryContainer,
                ),
                child: Icon(
                  draft.isVenue
                      ? venueIcon(category: draft.category, maki: draft.maki)
                      : Icons.flag_rounded,
                  size: 20,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.displayLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (draft.isVenue && draft.category != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        draft.category!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      draft.resolvingAddress
                          ? 'Looking up the address…'
                          : draft.hasPoint
                          ? (draft.isVenue ? draft.detail : draft.coordinates)
                          : 'Tap a place or the map to choose a point',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (draft.resolvingAddress)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 3),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canConfirm ? onConfirm : null,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_rounded, size: 18),
              label: Text(
                saving ? 'Setting destination…' : 'Set as Group Destination',
              ),
            ),
          ),
          if (!configured) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your Mapbox public token to mapbox.env.json and restart the '
              'app to use the map.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (hasActiveDestination) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: saving ? null : onEnd,
                child: Text(
                  'End current navigation',
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin({required this.moving, required this.color});

  final bool moving;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: const Offset(0, -26),
            child: AnimatedScale(
              scale: moving ? 1.14 : 1,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: moving ? 0.34 : 0.22,
                          ),
                          blurRadius: moving ? 16 : 8,
                          offset: Offset(0, moving ? 8 : 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  CustomPaint(
                    size: const Size(14, 10),
                    painter: _PinTailPainter(color),
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

class _PinTailPainter extends CustomPainter {
  const _PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => oldDelegate.color != color;
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _MapRoundButton(
      icon: Icons.my_location_rounded,
      tooltip: 'My location',
      onTap: onTap,
    );
  }
}

/// Shown after a manual pan during a trip; restores the angled tracking view.
class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: 'Re-center',
      child: Material(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.my_location_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Re-center',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
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

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.96),
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _MissingMapToken extends StatelessWidget {
  const _MissingMapToken();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.surfaceContainerHigh, scheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_rounded, size: 22, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text('Mapbox token needed', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Start the app with '
              '--dart-define-from-file=mapbox.env.json so the map can load.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
