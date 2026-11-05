import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../domain/ethiopian_pet.dart';
import '../../domain/pet_mood.dart';
import '../pet_mood_visuals.dart';
import '../sticker_assets.dart';
import 'pet_avatar.dart';

/// A companion portrait that moves with the circle's mood.
///
/// A shipped sticker file (`assets/pets/<id>/<mood>.json`) wins when one
/// exists. Otherwise the portrait animates procedurally, so a pet without art
/// still breathes, hops or naps instead of going blank.
class AnimatedPetSticker extends StatefulWidget {
  const AnimatedPetSticker({
    super.key,
    required this.pet,
    this.mood = PetMood.idle,
    this.size = 84,
    this.showParticles = true,
    this.interactive = true,
    this.onTap,
    this.lottieAsset,
  });

  final EthiopianPet pet;
  final PetMood mood;
  final double size;

  /// Celebration sparkles and sleeping z's. Off for dense rows and carousels.
  final bool showParticles;

  /// Whether a tap reacts like a Telegram sticker.
  final bool interactive;

  final VoidCallback? onTap;

  /// Pins one sticker file instead of resolving it from the bundle.
  final String? lottieAsset;

  @override
  State<AnimatedPetSticker> createState() => _AnimatedPetStickerState();
}

class _AnimatedPetStickerState extends State<AnimatedPetSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reaction;
  Future<Set<String>>? _assets;

  @override
  void initState() {
    super.initState();
    _reaction = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assets ??= PetStickerAssets.of(DefaultAssetBundle.of(context));
  }

  @override
  void dispose() {
    _reaction.dispose();
    super.dispose();
  }

  void _react() {
    HapticFeedback.lightImpact();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _reaction.forward(from: 0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.mood.accent(scheme);

    Widget body = AnimatedBuilder(
      animation: _reaction,
      child: _switcher(accent),
      builder: (context, child) {
        final reaction = _Reaction.of(_reaction.value);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(0, -widget.size * reaction.lift),
              child: Transform.scale(
                scaleX: reaction.scaleX,
                scaleY: reaction.scaleY,
                child: child,
              ),
            ),
            if (reaction.burst > 0)
              _HeartBurst(
                progress: reaction.burst,
                size: widget.size,
                color: accent,
              ),
          ],
        );
      },
    );

    body = Semantics(
      image: true,
      button: widget.interactive,
      hint: widget.onTap == null ? null : 'Opens the companion card',
      label: '${widget.pet.commonName}, ${widget.mood.label}',
      child: ExcludeSemantics(
        child: SizedBox(width: widget.size, height: widget.size, child: body),
      ),
    );

    if (widget.interactive) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _react,
        child: body,
      );
    }

    return RepaintBoundary(child: body);
  }

  Widget _switcher(Color accent) {
    final pet = widget.pet;
    final bundle = DefaultAssetBundle.of(context);
    final fallback = _ProceduralSticker(
      key: ValueKey('${pet.id}-${widget.mood.name}-fallback'),
      pet: pet,
      mood: widget.mood,
      size: widget.size,
      showParticles: widget.showParticles,
      accent: accent,
    );

    final pinned = widget.lottieAsset;
    if (pinned != null) {
      return _crossFade(
        _LottieSticker(
          key: ValueKey('$pinned-lottie'),
          asset: pinned,
          size: widget.size,
          bundle: bundle,
          fallback: fallback,
        ),
      );
    }

    return FutureBuilder<Set<String>>(
      future: _assets,
      builder: (context, snapshot) {
        final path = petStickerAssetPath(pet.id, widget.mood);
        final bundled = snapshot.data?.contains(path) ?? false;
        // When the manifest resolves without a sticker the same keyed fallback
        // stays mounted, so nothing re-runs as the future completes.
        return _crossFade(
          bundled
              ? _LottieSticker(
                  key: ValueKey('${pet.id}-${widget.mood.name}-lottie'),
                  asset: path,
                  size: widget.size,
                  bundle: bundle,
                  fallback: fallback,
                )
              : fallback,
        );
      },
    );
  }

  Widget _crossFade(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _LottieSticker extends StatelessWidget {
  const _LottieSticker({
    super.key,
    required this.asset,
    required this.size,
    required this.fallback,
    this.bundle,
  });

  final String asset;
  final double size;
  final Widget fallback;
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        asset,
        bundle: bundle,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
        animate: !MediaQuery.disableAnimationsOf(context),
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _ProceduralSticker extends StatefulWidget {
  const _ProceduralSticker({
    super.key,
    required this.pet,
    required this.mood,
    required this.size,
    required this.showParticles,
    required this.accent,
  });

  final EthiopianPet pet;
  final PetMood mood;
  final double size;
  final bool showParticles;
  final Color accent;

  @override
  State<_ProceduralSticker> createState() => _ProceduralStickerState();
}

class _ProceduralStickerState extends State<_ProceduralSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _Motion.durationFor(widget.mood),
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
  void didUpdateWidget(covariant _ProceduralSticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _controller.duration = _Motion.durationFor(widget.mood);
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
    final size = widget.size;
    // The portrait is built once and only transformed on every frame.
    final portrait = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.035),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.accent.withValues(alpha: 0.16),
        border: Border.all(
          color: widget.accent.withValues(alpha: 0.35),
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

    if (MediaQuery.disableAnimationsOf(context)) {
      return SizedBox(width: size, height: size, child: portrait);
    }

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        child: portrait,
        builder: (context, child) {
          final t = _controller.value;
          final motion = _Motion.of(widget.mood, t, size);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.showParticles)
                _Particles(
                  mood: widget.mood,
                  t: t,
                  size: size,
                  color: widget.accent,
                ),
              Transform.translate(
                offset: Offset(0, motion.lift),
                child: Transform.rotate(
                  angle: motion.tilt,
                  child: Transform.scale(
                    scaleX: motion.scale,
                    scaleY: motion.scale * motion.squash,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The tap answer: a quick squash-and-stretch bounce, then settle.
class _Reaction {
  const _Reaction({
    required this.scaleX,
    required this.scaleY,
    required this.lift,
    required this.burst,
  });

  final double scaleX;
  final double scaleY;
  final double lift;
  final double burst;

  static _Reaction of(double t) {
    if (t <= 0 || t >= 1) {
      return const _Reaction(scaleX: 1, scaleY: 1, lift: 0, burst: 0);
    }
    final wave = math.sin(t * math.pi * 2.4) * math.exp(-3.2 * t);
    return _Reaction(
      scaleX: 1 + wave * 0.12,
      scaleY: 1 - wave * 0.12,
      lift: math.sin(t * math.pi) * 0.06,
      burst: t < 0.8 ? t / 0.8 : 0,
    );
  }
}

class _HeartBurst extends StatelessWidget {
  const _HeartBurst({
    required this.progress,
    required this.size,
    required this.color,
  });

  final double progress;
  final double size;
  final Color color;

  static const _angles = [-2.15, -1.57, -0.99];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < _angles.length; i++) _heart(i),
        ],
      ),
    );
  }

  Widget _heart(int index) {
    final t = ((progress - index * 0.10) / 0.75).clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();
    final angle = _angles[index];
    final distance = size * 0.48 * t;
    return Transform.translate(
      offset: Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance - size * 0.08 * t,
      ),
      child: Opacity(
        opacity: math.sin(t * math.pi).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.5 + t * 0.7,
          child: Icon(
            Icons.favorite_rounded,
            size: size * (0.15 - index * 0.015),
            color: color,
          ),
        ),
      ),
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

  static Duration durationFor(PetMood mood) => switch (mood) {
    PetMood.idle => const Duration(milliseconds: 3200),
    PetMood.traveling => const Duration(milliseconds: 1100),
    PetMood.celebrating => const Duration(milliseconds: 1500),
    PetMood.sleeping => const Duration(milliseconds: 4200),
  };

  static _Motion of(PetMood mood, double t, double size) {
    final turn = t * 2 * math.pi;
    return switch (mood) {
      PetMood.idle => _Motion(
        lift: math.sin(turn) * size * 0.008,
        // A slow 1.0 → 1.05 breath, with a quick blink late in the cycle.
        scale: 1 + (0.5 + 0.5 * math.sin(turn)) * 0.05,
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
