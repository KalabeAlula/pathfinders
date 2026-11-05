import 'dart:async';

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
/// Mapbox's annotation managers are unavailable on web, so the layer simply
/// stays inert there and the Flutter chrome still renders.
class MapboxLiveAnnotations {
  MapboxLiveAnnotations(this._map, {this.iconScale = 0.46});

  final MapboxMap _map;
  final double iconScale;

  PointAnnotationManager? _members;
  PointAnnotationManager? _destination;
  PolylineAnnotationManager? _routes;
  Cancelable? _memberTaps;
  ValueChanged<String>? onMemberTapped;

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
  bool get isSupported => !kIsWeb && !_disposed;

  Future<void> initialize() async {
    if (kIsWeb || _disposed) return;
    final generation = ++_generation;
    try {
      _routes = await _map.annotations.createPolylineAnnotationManager(
        id: 'live-routes-$generation',
      );
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
      // A web build or a style swap that raced the factory.
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
