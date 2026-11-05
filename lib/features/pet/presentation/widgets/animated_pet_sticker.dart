import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/ethiopian_pet.dart';
import '../../domain/pet_mood.dart';
import '../pet_mood_visuals.dart';
import 'pet_avatar.dart';

/// A companion portrait that moves with the circle's mood.
///
/// One looping controller drives every state; the portrait is passed as the
/// [AnimatedBuilder] child so frames only transform it, never rebuild it. The
/// whole sticker sits in a [RepaintBoundary] so a busy tab does not repaint it.
class AnimatedPetSticker extends StatefulWidget {
  const AnimatedPetSticker({
    super.key,
    required this.pet,
    this.mood = PetMood.idle,
    this.size = 84,
    this.showParticles = true,
  });

  final EthiopianPet pet;
  final PetMood mood;
  final double size;

  /// Celebration sparkles and sleeping z's. Off for dense rows and carousels.
  final bool showParticles;

  @override
  State<AnimatedPetSticker> createState() => _AnimatedPetStickerState();
}

class _AnimatedPetStickerState extends State<AnimatedPetSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size;
    final accent = widget.mood.accent(scheme);

    // The portrait is built once and reused by every frame.
    final portrait = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.035),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.16),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: size * 0.02,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: PetAvatar(pet: widget.pet, size: size * 0.86),
    );

    final body = MediaQuery.disableAnimationsOf(context)
        ? portrait
        : AnimatedBuilder(
            animation: _controller,
            child: portrait,
            builder: (context, child) => _frame(
              child!,
              _Motion.of(widget.mood, _controller.value, size),
              size,
              accent,
              scheme,
            ),
          );

    return RepaintBoundary(
      child: Semantics(
        image: true,
        label: '${widget.pet.commonName}, ${widget.mood.label}',
        child: ExcludeSemantics(
          child: SizedBox(width: size, height: size, child: body),
        ),
      ),
    );
  }

  Widget _frame(
    Widget portrait,
    _Motion motion,
    double size,
    Color accent,
    ColorScheme scheme,
  ) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.showParticles) ...[
          _Particles(
            mood: widget.mood,
            t: _controller.value,
            size: size,
            color: accent,
          ),
        ],
        Transform.translate(
          offset: Offset(0, motion.lift),
          child: Transform.rotate(
            angle: motion.tilt,
            child: Transform.scale(
              scaleX: motion.scale,
              scaleY: motion.scale * motion.squash,
              child: portrait,
            ),
          ),
        ),
      ],
    );
  }
}

class _Motion {
  const _Motion({
    this.lift = 0,
    this.scale = 1,
    this.squash = 1,
    this.tilt = 0,
  });

  final double lift;
  final double scale;
  final double squash;
  final double tilt;

  static _Motion of(PetMood mood, double t, double size) {
    final turn = t * 2 * math.pi;
    return switch (mood) {
      PetMood.idle => _Motion(
        lift: math.sin(turn) * size * 0.012,
        scale: 1 + math.sin(turn) * 0.01,
        tilt: math.sin(turn) * 0.012,
        squash: _blink(t),
      ),
      PetMood.traveling => () {
        final stride = (t * 2) % 1;
        final hop = stride * 2 * math.pi;
        return _Motion(
          lift: -math.sin(hop).abs() * size * 0.045,
          scale: 1 + math.sin(hop).abs() * 0.02,
          squash: 1 - math.sin(hop).abs() * 0.02,
          tilt: 0.035 + math.sin(hop) * 0.035,
        );
      }(),
      PetMood.celebrating => () {
        final bounce = (t * 3) % 1;
        final hop = bounce * math.pi;
        return _Motion(
          lift: -math.sin(hop) * size * 0.14,
          scale: 1 + math.sin(hop) * 0.05,
          squash: 1 - math.sin(hop) * 0.04,
          tilt: math.sin(turn * 3) * 0.09,
        );
      }(),
      PetMood.sleeping => _Motion(
        lift: size * 0.01 + math.sin(turn * 0.5) * size * 0.006,
        scale: 1 + math.sin(turn * 0.5) * 0.018,
        tilt: 0.10 + math.sin(turn * 0.5) * 0.008,
      ),
    };
  }

  /// A quick eyelid squash late in each idle cycle.
  static double _blink(double t) {
    final progress = ((t - 0.84) / 0.05).clamp(0.0, 1.0);
    return 1 - math.sin(progress * math.pi) * 0.10;
  }
}

/// Mood accents that drift around the portrait: hearts and stars for a
/// celebration, soft z's for a nap.
class _Particles extends StatelessWidget {
  const _Particles({
    required this.mood,
    required this.t,
    required this.size,
    required this.color,
  });

  final PetMood mood;
  final double t;
  final double size;
  final Color color;

  static const _celebration = [
    (angle: -2.5, offset: 0.0, icon: Icons.favorite_rounded),
    (angle: -1.9, offset: 0.35, icon: Icons.star_rounded),
    (angle: -1.2, offset: 0.6, icon: Icons.auto_awesome_rounded),
    (angle: -0.7, offset: 0.15, icon: Icons.favorite_rounded),
    (angle: -0.2, offset: 0.5, icon: Icons.star_rounded),
    (angle: 0.3, offset: 0.8, icon: Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (mood == PetMood.celebrating) {
      return IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final particle in _celebration)
              _float(
                progress: (t + particle.offset) % 1,
                angle: particle.angle,
                spread: 0.9,
                child: Icon(
                  particle.icon,
                  size: size * 0.14,
                  color: color,
                ),
              ),
          ],
        ),
      );
    }
    if (mood == PetMood.sleeping) {
      return IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < 3; i++)
              _float(
                progress: (t + i / 3) % 1,
                angle: -0.9 - i * 0.12,
                spread: 0.75,
                child: Text(
                  'z',
                  style: TextStyle(
                    fontSize: size * (0.13 + i * 0.03),
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _float({
    required double progress,
    required double angle,
    required double spread,
    required Widget child,
  }) {
    final distance = size * spread * progress;
    return Transform.translate(
      offset: Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance - size * 0.12 * progress,
      ),
      child: Opacity(
        opacity: math.sin(progress * math.pi).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.55 + progress * 0.6,
          child: child,
        ),
      ),
    );
  }
}
