import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen confirmation + tactile burst shown after sending a nudge.
class NudgeOverlay extends StatefulWidget {
  const NudgeOverlay({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<NudgeOverlay> createState() => _NudgeOverlayState();
}

class _NudgeOverlayState extends State<NudgeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  Timer? _secondHaptic;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _secondHaptic = Timer(
      const Duration(milliseconds: 280),
      HapticFeedback.mediumImpact,
    );
  }

  @override
  void dispose() {
    _secondHaptic?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final fade = t < 0.78 ? 1.0 : (1 - (t - 0.78) / 0.22).clamp(0.0, 1.0);
          final rings = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

          return Opacity(
            opacity: fade,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.52 * fade),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      if (rings - i * 0.12 > 0)
                        _Halo(
                          progress: (rings - i * 0.12).clamp(0.0, 1.0),
                          color: scheme.primary,
                        ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale:
                              0.9 +
                              0.1 *
                                  Curves.easeOutBack.transform(
                                    t.clamp(0.0, 1.0),
                                  ),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [scheme.primary, scheme.tertiary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 40,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ((1 - progress) * 0.5).clamp(0, 1),
      child: Transform.scale(
        scale: 0.5 + progress * 2.4,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.65),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
