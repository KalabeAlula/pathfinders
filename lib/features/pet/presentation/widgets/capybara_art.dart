import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/shared_pet.dart';
import '../pet_visuals.dart';

/// Hand-painted capybara so the shared pet works offline and without binary
/// assets. A Rive state machine can replace the painter later without changing
/// the surrounding card.
class CapybaraArt extends StatefulWidget {
  const CapybaraArt({super.key, required this.mood, this.size = 80});

  final PetMood mood;
  final double size;

  @override
  State<CapybaraArt> createState() => _CapybaraArtState();
}

class _CapybaraArtState extends State<CapybaraArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 0.985, end: 1.015)
      .animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut));

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeIcon = widget.mood.badgeIcon;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: _scale,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _CapybaraPainter(mood: widget.mood),
            ),
          ),
          if (badgeIcon != null)
            Positioned(
              top: -2,
              right: -2,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey(widget.mood),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerLowest,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Icon(
                    badgeIcon,
                    size: 13,
                    color: widget.mood.badgeColor(scheme),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CapybaraPainter extends CustomPainter {
  _CapybaraPainter({required this.mood});

  final PetMood mood;

  static const Color _fur = Color(0xFFBB8E68);
  static const Color _furDark = Color(0xFF8A6245);
  static const Color _muzzle = Color(0xFFDDBB97);
  static const Color _paw = Color(0xFFCFA480);
  static const Color _eye = Color(0xFF3C2B20);
  static const Color _blush = Color(0xFFDD8F72);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final furPaint = Paint()..color = _fur;
    final furOutline = Paint()
      ..color = _furDark.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012;
    final muzzlePaint = Paint()..color = _muzzle;
    final pawPaint = Paint()..color = _paw;
    final darkPaint = Paint()..color = _eye;
    final earInnerPaint = Paint()..color = _furDark.withValues(alpha: 0.55);
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final blushPaint = Paint()
      ..color = _blush.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Ears behind the head.
    canvas.drawCircle(p(0.30, 0.28), s * 0.095, furPaint);
    canvas.drawCircle(p(0.70, 0.28), s * 0.095, furPaint);
    canvas.drawCircle(p(0.30, 0.28), s * 0.048, earInnerPaint);
    canvas.drawCircle(p(0.70, 0.28), s * 0.048, earInnerPaint);

    // Head.
    final head = Rect.fromCenter(
      center: p(0.50, 0.56),
      width: s * 0.72,
      height: s * 0.60,
    );
    canvas.drawOval(head, furPaint);
    canvas.drawOval(head, furOutline);

    // Forehead highlight and muzzle.
    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.43, 0.36),
        width: s * 0.20,
        height: s * 0.10,
      ),
      highlightPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.50, 0.66),
        width: s * 0.42,
        height: s * 0.26,
      ),
      muzzlePaint,
    );

    // Blush.
    canvas.drawCircle(p(0.28, 0.61), s * 0.055, blushPaint);
    canvas.drawCircle(p(0.72, 0.61), s * 0.055, blushPaint);

    _drawEyes(canvas, s, darkPaint);
    _drawNoseAndMouth(canvas, s, darkPaint);

    // Paws peeking at the bottom.
    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.35, 0.855),
        width: s * 0.17,
        height: s * 0.085,
      ),
      pawPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: p(0.65, 0.855),
        width: s * 0.17,
        height: s * 0.085,
      ),
      pawPaint,
    );

    // Tiny hair tuft.
    final tuft = Paint()
      ..color = _furDark.withValues(alpha: 0.5)
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = 0.47 + i * 0.03;
      canvas.drawLine(p(x, 0.265), p(x + 0.012, 0.225), tuft);
    }

    if (mood == PetMood.dirty) {
      final smudge = Paint()..color = _furDark.withValues(alpha: 0.25);
      canvas.drawOval(
        Rect.fromCenter(
          center: p(0.70, 0.47),
          width: s * 0.07,
          height: s * 0.045,
        ),
        smudge,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: p(0.30, 0.53),
          width: s * 0.05,
          height: s * 0.035,
        ),
        smudge,
      );
    }
  }

  void _drawEyes(Canvas canvas, double s, Paint dark) {
    Offset p(double x, double y) => Offset(x * s, y * s);
    final stroke = Paint()
      ..color = _eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round;

    for (final x in [0.385, 0.615]) {
      switch (mood) {
        case PetMood.happy:
        case PetMood.playing:
          final path = Path()
            ..moveTo((x - 0.048) * s, 0.50 * s)
            ..quadraticBezierTo(x * s, 0.445 * s, (x + 0.048) * s, 0.50 * s);
          canvas.drawPath(path, stroke);
        case PetMood.sleepy:
          final path = Path()
            ..moveTo((x - 0.04) * s, 0.49 * s)
            ..quadraticBezierTo(x * s, 0.51 * s, (x + 0.04) * s, 0.49 * s);
          canvas.drawPath(path, stroke);
        case PetMood.hungry:
          canvas.drawCircle(p(x, 0.49), s * 0.036, dark);
          canvas.drawCircle(
            Offset((x - 0.012) * s, 0.478 * s),
            s * 0.011,
            Paint()..color = Colors.white.withValues(alpha: 0.85),
          );
        case PetMood.dirty:
          canvas.drawCircle(p(x, 0.49), s * 0.03, dark);
        case PetMood.content:
          canvas.drawCircle(p(x, 0.49), s * 0.028, dark);
          canvas.drawCircle(
            Offset((x - 0.009) * s, 0.48 * s),
            s * 0.0075,
            Paint()..color = Colors.white.withValues(alpha: 0.8),
          );
      }
    }

    if (mood == PetMood.hungry) {
      final brow = Paint()
        ..color = _eye
        ..strokeWidth = s * 0.015
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p(0.33, 0.43), p(0.43, 0.45), brow);
      canvas.drawLine(p(0.57, 0.45), p(0.67, 0.43), brow);
    }
  }

  void _drawNoseAndMouth(Canvas canvas, double s, Paint dark) {
    Offset p(double x, double y) => Offset(x * s, y * s);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: p(0.50, 0.612),
          width: s * 0.085,
          height: s * 0.05,
        ),
        Radius.circular(s * 0.024),
      ),
      dark,
    );

    final mouthStroke = Paint()
      ..color = _eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case PetMood.playing:
        canvas.drawOval(
          Rect.fromCenter(
            center: p(0.50, 0.705),
            width: s * 0.12,
            height: s * 0.085,
          ),
          dark,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: p(0.50, 0.735),
            width: s * 0.06,
            height: s * 0.035,
          ),
          Paint()..color = const Color(0xFFE8927C),
        );
      case PetMood.hungry:
        canvas.drawOval(
          Rect.fromCenter(
            center: p(0.50, 0.70),
            width: s * 0.085,
            height: s * 0.06,
          ),
          dark,
        );
      case PetMood.sleepy:
        canvas.drawLine(p(0.47, 0.695), p(0.53, 0.695), mouthStroke);
      case PetMood.dirty:
        canvas.drawLine(p(0.46, 0.70), p(0.54, 0.70), mouthStroke);
      case PetMood.happy:
      case PetMood.content:
        final path = Path()
          ..moveTo(0.44 * s, 0.675 * s)
          ..quadraticBezierTo(0.50 * s, 0.735 * s, 0.56 * s, 0.675 * s);
        canvas.drawPath(path, mouthStroke);
    }

    if (mood == PetMood.playing || mood == PetMood.happy) {
      final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.65);
      final angle = math.pi / 4;
      for (final center in [p(0.20, 0.38), p(0.80, 0.42)]) {
        for (var i = 0; i < 2; i++) {
          final rotation = angle + i * math.pi / 2;
          final dx = math.cos(rotation) * s * 0.028;
          final dy = math.sin(rotation) * s * 0.028;
          canvas.drawLine(
            center - Offset(dx, dy),
            center + Offset(dx, dy),
            Paint()
              ..color = sparkle.color
              ..strokeWidth = s * 0.012
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CapybaraPainter oldDelegate) =>
      oldDelegate.mood != mood;
}
