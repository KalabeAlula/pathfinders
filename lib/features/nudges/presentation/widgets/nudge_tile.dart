import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/bento_card.dart';

class NudgeTile extends StatefulWidget {
  const NudgeTile({super.key, required this.onSend, this.isSending = false});

  final VoidCallback onSend;
  final bool isSending;

  @override
  State<NudgeTile> createState() => _NudgeTileState();
}

class _NudgeTileState extends State<NudgeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onContainer = scheme.onPrimaryContainer;

    return BentoCard(
      padding: EdgeInsets.zero,
      semanticLabel: 'Send a thinking-of-you nudge to the circle',
      gradient: LinearGradient(
        colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: scheme.primary.withValues(alpha: 0.25),
      onTap: widget.isSending ? null : widget.onSend,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    return SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            _Ring(
                              progress: (_pulse.value + i / 3) % 1,
                              color: scheme.primary,
                            ),
                          child!,
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                    ),
                    child: widget.isSending
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.wifi_tethering_rounded,
                            size: 19,
                            color: scheme.onPrimary,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                'Nudge',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: onContainer, fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: Text(
                'Send warmth',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onContainer.withValues(alpha: 0.72),
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = 0.55 + progress * 0.7;
    return Opacity(
      opacity: ((1 - progress) * 0.5).clamp(0, 1),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
        ),
      ),
    );
  }
}
