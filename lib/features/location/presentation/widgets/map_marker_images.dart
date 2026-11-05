import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../profile/domain/animal_avatar.dart';

/// Bitmaps for Mapbox point annotations.
///
/// The native annotation layer draws images rather than Flutter widgets, so
/// avatars and the destination pin are painted once and cached by appearance.
/// PointAnnotationManager uploads these bytes into the style as images, which
/// keeps panning and rotating on the native render loop.
abstract final class MapMarkerImages {
  static final Map<String, Future<Uint8List>> _cache = {};
  static final Map<String, Future<ui.Image?>> _avatarImages = {};

  static Future<Uint8List> memberAvatar({
    required String avatarId,
    required String initials,
    required Color accent,
    required Color background,
    bool approximate = false,
    bool isCurrentUser = false,
  }) {
    final key =
        'member:$avatarId:$initials:${accent.toARGB32()}:'
        '${background.toARGB32()}:$approximate:$isCurrentUser';
    return _cache.putIfAbsent(
      key,
      () => _paintMemberAvatar(
        avatarId: avatarId,
        initials: initials,
        accent: accent,
        background: background,
        approximate: approximate,
        isCurrentUser: isCurrentUser,
      ),
    );
  }

  static Future<Uint8List> destination({required Color color}) {
    final key = 'destination:${color.toARGB32()}';
    return _cache.putIfAbsent(key, () => _paintDestination(color));
  }

  /// A soft ring laid over the tapped POI so the selection reads without
  /// covering the basemap's own icon and label.
  static Future<Uint8List> venueHighlight({required Color color}) {
    final key = 'venue:${color.toARGB32()}';
    return _cache.putIfAbsent(key, () => _paintVenueHighlight(color));
  }

  static Future<Uint8List> _paintMemberAvatar({
    required String avatarId,
    required String initials,
    required Color accent,
    required Color background,
    required bool approximate,
    required bool isCurrentUser,
  }) async {
    // Extra height below the circle holds the location triangle; the
    // annotation is anchored at the triangle tip.
    const width = 112.0;
    const height = 144.0;
    const center = Offset(width / 2, 50);
    const radius = 41.0;
    final ringColor = approximate ? const Color(0xFFE0A93E) : accent;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Anchor triangle, drawn first so the badge overlaps its base.
    final triangle = Path()
      ..moveTo(width / 2 - 12, center.dy + radius - 4)
      ..lineTo(width / 2, height - 2)
      ..lineTo(width / 2 + 12, center.dy + radius - 4)
      ..close();

    canvas.drawPath(
      triangle.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x3D000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(triangle, Paint()..color = Colors.white);
    canvas.save();
    canvas.translate(width / 2, center.dy + radius - 4);
    canvas.scale(0.72);
    canvas.translate(-width / 2, -(center.dy + radius - 4));
    canvas.drawPath(triangle, Paint()..color = ringColor);
    canvas.restore();

    // Shadow and outer ring. The local member gets a wider double ring so
    // "You" reads at a glance even among four peers.
    canvas.drawCircle(
      center + const Offset(0, 3),
      radius + (isCurrentUser ? 6 : 4),
      Paint()
        ..color = const Color(0x45000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      center,
      radius + (isCurrentUser ? 7 : 5),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      radius + (isCurrentUser ? 6 : 4),
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrentUser ? 4.5 : 3.5,
    );

    final image = await _loadAvatar(AnimalAvatar.byId(avatarId).assetPath);
    final face = Rect.fromCircle(center: center, radius: radius);
    if (image != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(face));
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        face,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, radius, Paint()..color = background);
      final painter = TextPainter(
        text: TextSpan(
          text: initials,
          style: TextStyle(
            color: Color.lerp(accent, Colors.black, 0.28),
            fontSize: initials.length > 2 ? 24 : 30,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          center.dx - painter.width / 2,
          center.dy - painter.height / 2,
        ),
      );
    }

    return _encode(recorder, width, height);
  }

  static Future<ui.Image?> _loadAvatar(String assetPath) {
    return _avatarImages.putIfAbsent(assetPath, () async {
      try {
        final data = await rootBundle.load(assetPath);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 192,
          targetHeight: 192,
        );
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        return null;
      }
    });
  }

  static Future<Uint8List> _paintDestination(Color color) async {
    const width = 76.0;
    const height = 96.0;
    const circleY = 36.0;

    final pin = Path()
      ..addOval(
        Rect.fromCircle(center: const Offset(width / 2, circleY), radius: 30),
      )
      ..moveTo(width / 2 - 15, circleY + 22)
      ..lineTo(width / 2, height - 4)
      ..lineTo(width / 2 + 15, circleY + 22)
      ..close();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawPath(
      pin.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x4D000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(pin, Paint()..color = Colors.white);
    canvas.save();
    canvas.translate(width / 2, circleY);
    canvas.scale(0.84);
    canvas.translate(-width / 2, -circleY);
    canvas.drawPath(pin, Paint()..color = color);
    canvas.restore();

    canvas.drawCircle(
      const Offset(width / 2, circleY),
      8,
      Paint()..color = Colors.white,
    );

    return _encode(recorder, width, height);
  }

  static Future<Uint8List> _paintVenueHighlight(Color color) async {
    const size = 140.0;
    const center = Offset(size / 2, size / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      center,
      54,
      Paint()..color = color.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      center,
      52,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11,
    );
    canvas.drawCircle(
      center,
      52,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    return _encode(recorder, size, size);
  }

  static Future<Uint8List> _encode(
    ui.PictureRecorder recorder,
    double width,
    double height,
  ) async {
    final image = await recorder.endRecording().toImage(
      width.round(),
      height.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }
}
