import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The soft, bordered surface used by every dashboard tile.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.gradient,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? scheme.surfaceContainerLow) : null,
      gradient: gradient,
      borderRadius: radius,
      border: Border.all(
        color: borderColor ?? scheme.outlineVariant.withValues(alpha: 0.75),
      ),
      boxShadow: gradient == null && scheme.brightness == Brightness.light
          ? [
              BoxShadow(
                color: const Color(0xFF3A3028).withValues(alpha: 0.035),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ]
          : null,
    );

    if (onTap == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: decoration,
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
