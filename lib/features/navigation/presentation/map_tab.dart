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
import 'widgets/arrival_card.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/route_eta_card.dart';

const _fallbackCenter = GeoPoint(latitude: 8.999, longitude: 38.775);

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
  MapFocusRequest? _pendingFocus;
  int _appliedFocusRevision = 0;
  String? _error;

  /// The last camera the member saw. It is restored when the native map is
  /// remounted, so switching tabs does not lose their place.
  Point _cameraCenter = Point(
    coordinates: Position(_fallbackCenter.longitude, _fallbackCenter.latitude),
  );
  double _cameraZoom = 15.2;
  double _cameraBearing = 0;
  double _cameraPitch = MapboxStandardStyle.pickerPitch;
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

  GeoPoint _resolveInitialCenter() {
    final destination = ref
        .read(navigationControllerProvider(widget.circleId))
        .destination;
    if (destination != null) return destination.point;

    final reading = ref
        .read(telemetryControllerProvider(widget.currentUserId))
        .lastReading;
    return reading?.point ?? _fallbackCenter;
  }

  CameraViewportState _buildViewport() => CameraViewportState(
    center: _cameraCenter,
    zoom: _cameraZoom,
    bearing: _cameraBearing,
    pitch: _cameraPitch,
  );

  void _onVisibilityChanged() {
    if (!mounted) return;
    final foreground = _appVisibility.isForeground;
    if (foreground == _foreground) return;
    setState(() => _foreground = foreground);
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
    _setMoving(true);
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

      // The first idle after a venue flight is the camera arriving at a point
      // the draft already holds, so it must not be treated as a pan.
      if (_venueFlight) {
        _venueFlight = false;
        return;
      }

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
      messenger.showSnackBar(
        const SnackBar(content: Text('Waiting for a location fix…')),
      );
      return;
    }

    final map = _map;
    if (map == null) return;
    _setMoving(true);
    try {
      await map.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              reading.point.longitude,
              reading.point.latitude,
            ),
          ),
          zoom: 16.2,
          pitch: MapboxStandardStyle.pickerPitch,
        ),
        MapAnimationOptions(duration: 900),
      );
    } catch (_) {
      // Camera animations are best effort.
    }
    _setMoving(false);
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

    ref.listen(
      navigationControllerProvider(widget.circleId),
      (_, _) => _scheduleSync(),
    );
    ref.listen(
      circleSnapshotProvider(widget.currentUserId),
      (_, _) => _scheduleSync(),
    );
    ref.listen(mapFocusControllerProvider, (_, next) => _onFocusRequested(next));

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
                    ? MapWidget(
                        styleUri: MapboxStandardStyle.uri,
                        viewport: _viewport,
                        // A TextureView is composited inside the Flutter view,
                        // so it respects tab and route z-order. SurfaceView
                        // punches through Flutter's canvas on Android.
                        textureView:
                            !kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.android,
                        onMapCreated: _onMapCreated,
                        onStyleLoadedListener: _onStyleLoaded,
                        onCameraChangeListener: _onCameraChanged,
                        onMapIdleListener: (_) => unawaited(_handleIdle()),
                      )
                    // Mounted while the tab is hidden or the app is in the
                    // background; never painted because the tab is offstage.
                    : const ColoredBox(color: Colors.transparent),
              ),
              if (configured && draft.hasPoint && !draft.isVenue)
                Positioned.fill(
                  child: _CenterPin(moving: _moving, color: scheme.tertiary),
                ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 12,
                right: 12,
                child: MapSearchBar(
                  userId: widget.currentUserId,
                  unreadCount: unread,
                  onChat: _openChat,
                  onPlaceSelected: _selectSuggestion,
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: ShellDock.contentInset(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (navigation.destination != null) ...[
                      ArrivalCard(
                        circleId: widget.circleId,
                        currentUserId: widget.currentUserId,
                        compact: true,
                      ),
                      RouteEtaCard(
                        circleId: widget.circleId,
                        currentUserId: widget.currentUserId,
                        members: members,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (configured)
                      _LocateButton(onTap: () => unawaited(_goToMyLocation())),
                    const SizedBox(height: AppSpacing.sm),
                    _SelectionSheet(
                      draft: draft,
                      configured: configured,
                      saving: _saving,
                      error: _error,
                      hasActiveDestination: navigation.destination != null,
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
