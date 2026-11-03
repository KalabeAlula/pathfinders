import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Warm, centred page frame shared by the sign-in and circle setup screens.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surface,
                    isDark
                        ? scheme.surfaceContainer
                        : scheme.primaryContainer.withValues(alpha: 0.5),
                    scheme.surface,
                  ],
                  stops: const [0, 0.58, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _Blob(
              size: 240,
              color: scheme.tertiaryContainer.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _Blob(
              size: 290,
              color: scheme.secondaryContainer.withValues(alpha: 0.55),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.subtitle,
    this.title = 'Pathfinders',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 54});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.34);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.clay.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/branding/app_icon.png',
          width: size,
          height: size,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          fit: BoxFit.cover,
          semanticLabel: 'Pathfinders',
        ),
      ),
    );
  }
}

InputDecoration onboardingFieldDecoration(
  BuildContext context, {
  required String label,
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: scheme.surfaceContainerLowest,
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.4),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 1.4),
  );
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

/// Two-tab pill switch used to pick between sibling modes.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  }) : assert(values.length == labels.length);

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                selected: values[i] == selected,
                onTap: () => onChanged(values[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? scheme.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed status page used while a gate is loading or failed.
class GateStatus extends StatelessWidget {
  const GateStatus({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.showSpinner = false,
    this.footer,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool showSpinner;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AuthShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BrandMark(size: 64),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
          ],
          if (showSpinner) ...[
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
