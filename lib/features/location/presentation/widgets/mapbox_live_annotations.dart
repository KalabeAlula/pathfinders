import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../domain/geo_point.dart';
import 'map_marker_images.dart';

class MapMemberPin {
  const MapMemberPin({
    required this.id,
    required this.initials,
    required this.avatarId,
    required this.latitude,
    required this.longitude,
    required this.accent,
    required this.background,
    required this.approximate,
    required this.isCurrentUser,
  });

  final String id;
  final String initials;

  /// Catalog id resolved to artwork by [MapMarkerImages.memberAvatar].
  final String avatarId;
  final double latitude;
  final double longitude;
  final Color accent;
  final Color background;

  /// Approximate-mode members are drawn with a caution ring so the pin is
  /// never mistaken for an exact fix.
  final bool approximate;

  /// The local member gets a wider ring, making "You" easy to find.
  final bool isCurrentUser;

  String get signature =>
      '$id:$avatarId:${latitude.toStringAsFixed(5)}:'
      '${longitude.toStringAsFixed(5)}:'
      '${accent.toARGB32()}:$approximate:$isCurrentUser';
}

class MapRouteLine {
  const MapRouteLine({
    required this.memberId,
    required this.points,
    required this.color,
    required this.width,
    this.borderWidth = 1.5,
  });

  final String memberId;
  final List<GeoPoint> points;
  final Color color;
  final double width;

  /// Mapbox draws the border as a narrower stroke on top of the line, so this
  /// stays thin enough that the member color still dominates.
  final double borderWidth;

  String get signature {
    if (points.isEmpty) return '$memberId:empty:${color.toARGB32()}';
    final first = points.first;
    final last = points.last;
    return '$memberId:${points.length}:${color.toARGB32()}:$borderWidth:'
        '${first.latitude.toStringAsFixed(4)},'
        '${first.longitude.toStringAsFixed(4)}:'
        '${last.latitude.toStringAsFixed(4)},'
        '${last.longitude.toStringAsFixed(4)}';
  }
}

/// Draws members, routes, and the shared destination on a Mapbox map.
///
/// Phones use the annotation managers. Web's annotation managers are stubs,
/// so the browser draws the same snapshot with a GeoJSON source and style
/// layers instead; the GL JS render loop keeps them glued to the basemap.
class MapboxLiveAnnotations {
  MapboxLiveAnnotations(this._map, {this.iconScale = 0.55});

  final MapboxMap _map;
  final double iconScale;

  PointAnnotationManager? _members;
  PointAnnotationManager? _destination;
  PolylineAnnotationManager? _routes;
  Cancelable? _memberTaps;
  ValueChanged<String>? onMemberTapped;

  /// Web-only: the sources and images behind the layers, so a style reload
  /// (which drops both) cannot leave syncs pointing at stale ids.
  String? _memberSourceId;
  String? _routeSourceId;
  String? _destinationSourceId;
  final Set<String> _webImages = {};

  bool _ready = false;
  bool _disposed = false;
  bool _busy = false;
  bool _queued = false;
  int _generation = 0;
  String? _appliedSignature;
  String? _inFlightSignature;

  _Snapshot _last = const _Snapshot(
    members: [],
    routes: [],
    destination: null,
    destinationColor: Colors.black,
  );

  /// True when this platform can draw annotations at all.
  bool get isSupported => !_disposed;

  Future<void> initialize() async {
    if (_disposed) return;
    if (kIsWeb) return _initializeWeb();
    final generation = ++_generation;
    try {
      _routes = await _map.annotations.createPolylineAnnotationManager(
        id: 'live-routes-$generation',
      );
      // Standard's night preset lights runtime layers, which turns route
      // colors nearly black; full emissive keeps them at their own value.
      await _routes!.setLineEmissiveStrength(1);
      _members = await _map.annotations.createPointAnnotationManager(
        id: 'live-members-$generation',
      );
      _destination = await _map.annotations.createPointAnnotationManager(
        id: 'live-destination-$generation',
      );
      await _members!.setIconAllowOverlap(true);
      await _members!.setTextAllowOverlap(true);
      await _destination!.setIconAllowOverlap(true);
      _memberTaps?.cancel();
      _memberTaps = _members!.tapEvents(
        onTap: (annotation) {
          final id = annotation.customData?['memberId'];
          if (id is String) onMemberTapped?.call(id);
        },
      );
      _ready = true;
    } catch (_) {
      // A style swap that raced the factory.
      _ready = false;
      return;
    }
    _appliedSignature = null;
    await _apply();
  }

  Future<void> sync({
    required List<MapMemberPin> members,
    required List<MapRouteLine> routes,
    required GeoPoint? destination,
    required Color destinationColor,
  }) {
    _last = _Snapshot(
      members: members,
      routes: routes,
      destination: destination,
      destinationColor: destinationColor,
    );
    if (!_ready || _disposed) return Future.value();
    return _apply();
  }

  Future<void> _apply() async {
    if (!_ready || _disposed) return;

    final snapshot = _last;
    final signature = _signatureOf(snapshot);
    if (_busy) {
      if (signature != _inFlightSignature) _queued = true;
      return;
    }
    if (signature == _appliedSignature) return;

    _busy = true;
    _inFlightSignature = signature;

    try {
      if (kIsWeb) {
        await _applyWeb(snapshot);
        _appliedSignature = signature;
        return;
      }
      final members = snapshot.members;
      final memberOptions = await Future.wait([
        for (final pin in members)
          MapMarkerImages.memberAvatar(
            avatarId: pin.avatarId,
            initials: pin.initials,
            accent: pin.accent,
            background: pin.background,
            approximate: pin.approximate,
            isCurrentUser: pin.isCurrentUser,
          ).then(
            (image) => PointAnnotationOptions(
              geometry: Point(
                coordinates: Position(pin.longitude, pin.latitude),
              ),
              image: image,
              iconSize: pin.isCurrentUser ? iconScale * 1.08 : iconScale,
              // The triangle tip marks the fix, not the circle centre.
              iconAnchor: IconAnchor.BOTTOM,
              customData: {'memberId': pin.id},
            ),
          ),
      ]);
      if (_disposed) return;

      await _members?.deleteAll();
      if (memberOptions.isNotEmpty) {
        await _members?.createMulti(memberOptions);
      }

      await _routes?.deleteAll();
      final lines = [
        for (final route in snapshot.routes)
          if (route.points.length > 1)
            PolylineAnnotationOptions(
              geometry: LineString(
                coordinates: [
                  for (final point in route.points)
                    Position(point.longitude, point.latitude),
                ],
              ),
              lineColor: route.color.toARGB32(),
              lineWidth: route.width,
              lineBorderColor: Colors.white.withValues(alpha: 0.9).toARGB32(),
              lineBorderWidth: route.borderWidth,
              lineJoin: LineJoin.ROUND,
            ),
      ];
      if (lines.isNotEmpty) {
        await _routes?.createMulti(lines);
      }

      await _destination?.deleteAll();
      final destination = snapshot.destination;
      if (destination != null) {
        final image = await MapMarkerImages.destination(
          color: snapshot.destinationColor,
        );
        if (_disposed) return;
        await _destination?.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                destination.longitude,
                destination.latitude,
              ),
            ),
            image: image,
            iconSize: 0.5,
            iconAnchor: IconAnchor.BOTTOM,
          ),
        );
      }

      _appliedSignature = signature;
    } catch (_) {
      // Losing the style invalidates the managers; the owner re-initializes
      // when the new style reports ready.
      _ready = false;
    } finally {
      _busy = false;
      _inFlightSignature = null;
      if (_queued && _ready) {
        _queued = false;
        await _apply();
      }
    }
  }

  /// Everything that changes what the native layer draws. Identical syncs are
  /// skipped so GPS ticks do not delete and recreate every annotation.
  static String _signatureOf(_Snapshot snapshot) {
    final buffer = StringBuffer();
    for (final pin in snapshot.members) {
      buffer
        ..write('m|${pin.id}|${pin.avatarId}|${pin.initials}|')
        ..write('${pin.latitude.toStringAsFixed(5)},')
        ..write('${pin.longitude.toStringAsFixed(5)}|')
        ..write('${pin.accent.toARGB32()}|${pin.background.toARGB32()}|')
        ..write('${pin.approximate}|${pin.isCurrentUser};');
    }
    for (final route in snapshot.routes) {
      buffer
        ..write('r|${route.memberId}|${route.color.toARGB32()}|')
        ..write('${route.width}|${route.borderWidth}|');
      for (final point in route.points) {
        buffer
          ..write(point.latitude.toStringAsFixed(5))
          ..write(',')
          ..write(point.longitude.toStringAsFixed(5))
          ..write(';');
      }
    }
    final destination = snapshot.destination;
    buffer
      ..write('d|${destination?.latitude},${destination?.longitude}|')
      ..write(snapshot.destinationColor.toARGB32());
    return buffer.toString();
  }

  /// Browser path: GL JS draws what the native annotation managers draw, using
  /// one GeoJSON source per snapshot plus symbol and line layers.
  Future<void> _initializeWeb() async {
    final suffix = '-${++_generation}';
    final style = _map;
    final members = 'live-members-src$suffix';
    final routes = 'live-routes-src$suffix';
    final destination = 'live-destination-src$suffix';
    try {
      for (final id in [members, routes, destination]) {
        await style.addStyleSource(
          id,
          '{"type":"geojson","data":{"type":"FeatureCollection",'
          '"features":[]}}',
        );
      }
      // The border is a wider white stroke under each route, mirroring the
      // native line-border the SDK paints around the member colour.
      await style.addStyleLayer(
        jsonEncode({
          'id': 'live-routes-border$suffix',
          'type': 'line',
          'source': routes,
          'layout': {'line-cap': 'round', 'line-join': 'round'},
          'paint': {
            'line-color': 'rgba(255,255,255,0.9)',
            'line-width': [
              '+',
              ['get', 'width'],
              [
                '*',
                ['get', 'border'],
                2,
              ],
            ],
            // Standard's night preset lights runtime layers; emissive keeps
            // the member colours from going black.
            'line-emissive-strength': 1,
          },
        }),
        null,
      );
      await style.addStyleLayer(
        jsonEncode({
          'id': 'live-routes$suffix',
          'type': 'line',
          'source': routes,
          'layout': {'line-cap': 'round', 'line-join': 'round'},
          'paint': {
            'line-color': ['get', 'color'],
            'line-width': ['get', 'width'],
            'line-emissive-strength': 1,
          },
        }),
        null,
      );
      await style.addStyleLayer(
        jsonEncode({
          'id': 'live-members$suffix',
          'type': 'symbol',
          'source': members,
          'layout': {
            'icon-image': ['get', 'image'],
            'icon-size': ['get', 'size'],
            'icon-anchor': 'bottom',
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
          },
        }),
        null,
      );
      await style.addStyleLayer(
        jsonEncode({
          'id': 'live-destination$suffix',
          'type': 'symbol',
          'source': destination,
          'layout': {
            'icon-image': ['get', 'image'],
            'icon-size': 0.5,
            'icon-anchor': 'bottom',
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
          },
        }),
        null,
      );
    } catch (_) {
      _ready = false;
      return;
    }
    _memberSourceId = members;
    _routeSourceId = routes;
    _destinationSourceId = destination;
    _webImages.clear();
    _ready = true;
    _appliedSignature = null;
    await _apply();
  }

  Future<void> _applyWeb(_Snapshot snapshot) async {
    final style = _map;

    final memberFeatures = <Map<String, Object?>>[];
    for (final pin in snapshot.members) {
      final imageId = _webMemberImageId(pin);
      await _ensureWebImage(
        imageId,
        () => MapMarkerImages.memberAvatar(
          avatarId: pin.avatarId,
          initials: pin.initials,
          accent: pin.accent,
          background: pin.background,
          approximate: pin.approximate,
          isCurrentUser: pin.isCurrentUser,
        ),
      );
      memberFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [pin.longitude, pin.latitude],
        },
        'properties': {
          'image': imageId,
          'size': pin.isCurrentUser ? iconScale * 1.08 : iconScale,
          'memberId': pin.id,
        },
      });
    }
    await style.setStyleSourceProperty(
      _memberSourceId!,
      'data',
      _featureCollection(memberFeatures),
    );

    await style.setStyleSourceProperty(
      _routeSourceId!,
      'data',
      _featureCollection([
        for (final route in snapshot.routes)
          if (route.points.length > 1)
            {
              'type': 'Feature',
              'geometry': {
                'type': 'LineString',
                'coordinates': [
                  for (final point in route.points)
                    [point.longitude, point.latitude],
                ],
              },
              'properties': {
                'color': _hex(route.color),
                'width': route.width,
                'border': route.borderWidth,
              },
            },
      ]),
    );

    final destination = snapshot.destination;
    if (destination == null) {
      await style.setStyleSourceProperty(
        _destinationSourceId!,
        'data',
        _featureCollection(const []),
      );
      return;
    }
    final imageId = 'pf-d:${snapshot.destinationColor.toARGB32()}';
    await _ensureWebImage(
      imageId,
      () => MapMarkerImages.destination(color: snapshot.destinationColor),
    );
    await style.setStyleSourceProperty(
      _destinationSourceId!,
      'data',
      _featureCollection([
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [destination.longitude, destination.latitude],
          },
          'properties': {'image': imageId},
        },
      ]),
    );
  }

  /// Uploads each avatar or pin bitmap once per style; re-adding an existing
  /// image id is what GL JS rejects, so the presence check stays.
  Future<void> _ensureWebImage(
    String imageId,
    Future<Uint8List> Function() bytes,
  ) async {
    if (!_webImages.add(imageId)) return;
    final style = _map;
    if (await style.hasStyleImage(imageId)) {
      await style.removeStyleImage(imageId);
    }
    await style.addImage(imageId, 1, StyleImageBytes(await bytes()));
  }

  static String _webMemberImageId(MapMemberPin pin) =>
      'pf-m:${pin.avatarId}:${pin.initials}:${pin.accent.toARGB32()}:'
      '${pin.background.toARGB32()}:${pin.approximate}:${pin.isCurrentUser}';

  static String _featureCollection(List<Map<String, Object?>> features) =>
      jsonEncode({'type': 'FeatureCollection', 'features': features});

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  void dispose() {
    _disposed = true;
    _ready = false;
    _memberTaps?.cancel();
    _memberTaps = null;
  }
}

class _Snapshot {
  const _Snapshot({
    required this.members,
    required this.routes,
    required this.destination,
    required this.destinationColor,
  });

  final List<MapMemberPin> members;
  final List<MapRouteLine> routes;
  final GeoPoint? destination;
  final Color destinationColor;
}
