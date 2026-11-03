import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Bitmaps for Mapbox point annotations.
///
/// The native annotation layer draws images rather than Flutter widgets, so
/// avatars and the destination pin are painted once and cached by appearance.
abstract final class MapMarkerImages {
  static final Map<String, Future<Uint8List>> _cache = {};

  static Future<Uint8List> member({
    required String initials,
    required Color accent,
    required Color background,
    bool approximate = false,
  }) {
    final key =
        'member:$initials:${accent.toARGB32()}:'
        '${background.toARGB32()}:$approximate';
    return _cache.putIfAbsent(
      key,
      () => _paintMember(
        initials: initials,
        accent: accent,
        background: background,
        approximate: approximate,
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

  static Future<Uint8List> _paintMember({
    required String initials,
    required Color accent,
    required Color background,
    required bool approximate,
  }) async {
    const size = 96.0;
    const center = Offset(size / 2, size / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      center + const Offset(0, 2),
      size / 2 - 8,
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, size / 2 - 5, Paint()..color = Colors.white);
    canvas.drawCircle(center, size / 2 - 9, Paint()..color = background);
    canvas.drawCircle(
      center,
      size / 2 - 5,
      Paint()
        ..color = approximate ? const Color(0xFFE0A93E) : accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: Color.lerp(accent, Colors.black, 0.28),
          fontSize: initials.length > 2 ? 26 : 34,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset((size - painter.width) / 2, (size - painter.height) / 2),
    );

    return _encode(recorder, size, size);
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
