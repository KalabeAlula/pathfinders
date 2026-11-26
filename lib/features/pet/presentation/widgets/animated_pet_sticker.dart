import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/ethiopian_pet.dart';
import '../../domain/pet_mood.dart';
import '../pet_mood_visuals.dart';
import '../sticker_assets.dart';
import 'cached_sticker.dart';
import 'pet_avatar.dart';

/// A companion portrait that moves with the circle's mood.
///
/// Bundled animated WebP expressions (`assets/pets/<id>/<mood>_<n>.webp`)
/// win when [TickerMode] is active and animations are enabled. Offscreen tabs
/// or reduced-motion settings fall back to the static [PetAvatar] PNG so
/// hidden tabs use zero decode CPU. Tapping cycles through expressions for the
/// current [mood] with a bouncy scale animation + medium haptic.
class AnimatedPetSticker extends StatefulWidget {
  const AnimatedPetSticker({
    super.key,
    required this.pet,
    this.mood = PetMood.idle,
    this.size = 84,
    this.showParticles = true,
    this.interactive = true,
    this.onTap,
    this.stickerAsset,
  });

  final EthiopianPet pet;
  final PetMood mood;
  final double size;

  /// Celebration sparkles and sleeping z's. Off for dense rows and carousels.
  final bool showParticles;

  /// Whether a tap reacts like a Telegram sticker.
  final bool interactive;

  final VoidCallback? onTap;

  /// Pins one sticker file instead of resolving expressions from the bundle.
  final String? stickerAsset;

  @override
  State<AnimatedPetSticker> createState() => _AnimatedPetStickerState();
}

class _AnimatedPetStickerState extends State<AnimatedPetSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reaction;
  bool _celebrated = false;
  int _expressionIndex = 0;

  // Speech bubble shown briefly after a tap.
  bool _showBubble = false;

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
    if (!_celebrated && widget.mood == PetMood.celebrating) {
      _celebrated = true;
      _celebrate();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedPetSticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet != widget.pet || oldWidget.mood != widget.mood) {
      _expressionIndex = 0;
    }
    if (oldWidget.mood != widget.mood && widget.mood == PetMood.celebrating) {
      _celebrate();
    }
  }

  @override
  void dispose() {
    _reaction.dispose();
    super.dispose();
  }

  void _react() {
    HapticFeedback.mediumImpact();
    setState(() {
      _expressionIndex++;
      _showBubble = true;
    });
    _celebrate();
    widget.onTap?.call();
    // Hide the speech bubble after 1.4 s.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  /// The arrival payoff / tap answer: squash-and-stretch bounce + heart burst.
  void _celebrate() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _reaction.forward(from: 0);
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
            if (_showBubble)
              _SpeechBubble(label: widget.pet.tapReply, size: widget.size),
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
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final animate = tickerEnabled && !disableAnimations;

    final fallback = _ProceduralSticker(
      key: ValueKey('${pet.id}-${widget.mood.name}-fallback'),
      pet: pet,
      mood: widget.mood,
      size: widget.size,
      showParticles: widget.showParticles,
      accent: accent,
    );

    // Pause animated decoding when hidden (e.g. offscreen IndexedStack tab)
    // or when reduced-motion is enabled — show the static PNG portrait.
    if (!animate) {
      return PetAvatar(
        key: ValueKey('${pet.id}-paused'),
        pet: pet,
        size: widget.size,
      );
    }

    final String? resolvedSource;
    if (widget.stickerAsset != null) {
      resolvedSource = widget.stickerAsset;
    } else {
      final expressions = PetStickerAssets.expressionsFor(pet.id, widget.mood);
      resolvedSource = expressions.isEmpty
          ? null
          : expressions[_expressionIndex % expressions.length];
    }

    if (resolvedSource == null) {
      return _crossFade(fallback);
    }

    // Check if it's a URL (remote) or asset path (local)
    final isRemote =
        resolvedSource.startsWith('http://') ||
        resolvedSource.startsWith('https://');

    if (isRemote) {
      return _crossFade(
        CachedNetworkSticker(
          key: ValueKey(resolvedSource),
          url: resolvedSource,
          size: widget.size,
          fallback: fallback,
        ),
      );
    } else {
      final bundle = DefaultAssetBundle.of(context);
      return _crossFade(
        _AnimatedImageSticker(
          key: ValueKey(resolvedSource),
          asset: resolvedSource,
          size: widget.size,
          bundle: bundle,
          fallback: fallback,
        ),
      );
    }
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

// ---------------------------------------------------------------------------
// Floating XP overlay — call [PetXpOverlay.show] from care buttons.
// ---------------------------------------------------------------------------

/// A self-removing "+XP" overlay that floats upward and fades out.
///
/// Usage:
/// ```dart
/// PetXpOverlay.show(context, xp: 8);
/// ```
class PetXpOverlay {
  PetXpOverlay._();

  static OverlayEntry? _entry;

  static void show(BuildContext context, {required int xp}) {
    _entry?.remove();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final center = box == null
        ? const Offset(0, 0)
        : box.localToGlobal(box.size.center(Offset.zero));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _XpBadge(
        center: center,
        xp: xp,
        onDone: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _XpBadge extends StatefulWidget {
  const _XpBadge({
    required this.center,
    required this.xp,
    required this.onDone,
  });

  final Offset center;
  final int xp;
  final VoidCallback onDone;

  @override
  State<_XpBadge> createState() => _XpBadgeState();
}

class _XpBadgeState extends State<_XpBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _dy;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _dy = Tween<double>(
      begin: 0,
      end: -52,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_ctrl);

    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Positioned(
        left: widget.center.dx - 20,
        top: widget.center.dy + _dy.value - 20,
        child: IgnorePointer(
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '+${widget.xp} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Speech bubble
// ---------------------------------------------------------------------------

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: -size * 0.42,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: scheme.onSurface),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated WebP image (local asset)
// ---------------------------------------------------------------------------

class _AnimatedImageSticker extends StatelessWidget {
  const _AnimatedImageSticker({
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
      child: Image.asset(
        asset,
        bundle: bundle,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Procedural sticker fallback (shown when WebP isn't available / off-screen)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Tap reaction: squash-and-stretch bounce + heart burst.
// ---------------------------------------------------------------------------

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
      scaleX: 1 + wave * 0.18,
      scaleY: 1 - wave * 0.18,
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
        children: [for (var i = 0; i < _angles.length; i++) _heart(i)],
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

// ---------------------------------------------------------------------------
// Motion — per-mood procedural animation parameters.
// ---------------------------------------------------------------------------

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
    // New moods — snappy energetic motions.
    PetMood.hyped => const Duration(milliseconds: 700),
    PetMood.curious => const Duration(milliseconds: 2800),
    PetMood.hungry => const Duration(milliseconds: 2500),
    PetMood.loved => const Duration(milliseconds: 2000),
  };

  static _Motion of(PetMood mood, double t, double size) {
    final turn = t * 2 * math.pi;
    return switch (mood) {
      PetMood.idle => _Motion(
        lift: math.sin(turn) * size * 0.008,
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
      // Hyped: fast vibrating bounce.
      PetMood.hyped => () {
        final bounce = (t * 4) % 1;
        final hop = bounce * math.pi;
        return _Motion(
          lift: -math.sin(hop) * size * 0.12,
          scale: 1 + math.sin(hop) * 0.07,
          squash: 1 - math.sin(hop) * 0.06,
          tilt: math.sin(turn * 6) * 0.12,
        );
      }(),
      // Curious: gentle head-tilt bob.
      PetMood.curious => _Motion(
        lift: math.sin(turn * 0.75) * size * 0.012,
        scale: 1 + math.sin(turn * 0.75) * 0.03,
        tilt: 0.08 * math.sin(turn * 0.5),
      ),
      // Hungry: slow droopy sway.
      PetMood.hungry => _Motion(
        lift: math.sin(turn * 0.6) * size * 0.015,
        scale: 1 + math.sin(turn * 0.6) * 0.02,
        tilt: math.sin(turn * 0.6) * 0.06,
      ),
      // Loved: gentle float + pulse.
      PetMood.loved => _Motion(
        lift: math.sin(turn) * size * 0.025,
        scale: 1 + math.sin(turn) * 0.045,
        tilt: math.sin(turn * 0.5) * 0.025,
      ),
    };
  }

  static double _blink(double t) {
    final progress = ((t - 0.84) / 0.05).clamp(0.0, 1.0);
    return 1 - math.sin(progress * math.pi) * 0.10;
  }
}

// ---------------------------------------------------------------------------
// Mood particles — celebration ✨, sleeping z's, hyped ⚡, loved ♥.
// ---------------------------------------------------------------------------

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

  static const _hyped = [
    (angle: -1.9, offset: 0.0, icon: Icons.bolt_rounded),
    (angle: -1.2, offset: 0.4, icon: Icons.bolt_rounded),
    (angle: -0.5, offset: 0.7, icon: Icons.star_rounded),
  ];

  static const _loved = [
    (angle: -2.0, offset: 0.0, icon: Icons.favorite_rounded),
    (angle: -1.57, offset: 0.3, icon: Icons.favorite_border_rounded),
    (angle: -1.1, offset: 0.6, icon: Icons.favorite_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (mood == PetMood.celebrating) {
      return IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final p in _celebration)
              _float(
                progress: (t + p.offset) % 1,
                angle: p.angle,
                spread: 0.9,
                child: Icon(p.icon, size: size * 0.14, color: color),
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
    if (mood == PetMood.hyped) {
      return IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final p in _hyped)
              _float(
                progress: (t + p.offset) % 1,
                angle: p.angle,
                spread: 0.7,
                child: Icon(p.icon, size: size * 0.12, color: color),
              ),
          ],
        ),
      );
    }
    if (mood == PetMood.loved) {
      return IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final p in _loved)
              _float(
                progress: (t + p.offset) % 1,
                angle: p.angle,
                spread: 0.6,
                child: Icon(p.icon, size: size * 0.11, color: color),
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
        child: Transform.scale(scale: 0.55 + progress * 0.6, child: child),
      ),
    );
  }
}
