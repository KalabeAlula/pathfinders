import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../circle/domain/group_type.dart';
import '../../domain/nudge.dart';

/// Lets the sender pick one of the warmth actions their group type offers.
/// Returns the chosen action, or null when the sheet is dismissed.
Future<NudgeWarmth?> showWarmthPicker(
  BuildContext context, {
  required GroupType type,
  required String memberName,
}) {
  return showModalBottomSheet<NudgeWarmth>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _WarmthPickerSheet(type: type, memberName: memberName),
  );
}

class _WarmthPickerSheet extends StatelessWidget {
  const _WarmthPickerSheet({required this.type, required this.memberName});

  final GroupType type;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = NudgeWarmth.optionsFor(type);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send $memberName some warmth',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'A small signal that you are thinking of them.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < options.length; index++)
                  _WarmthChip(
                    warmth: options[index],
                    index: index,
                    selected: index == 0,
                    onTap: () => Navigator.of(context).pop(options[index]),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Quick taps on a member card send the first one.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarmthChip extends StatelessWidget {
  const _WarmthChip({
    required this.warmth,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final NudgeWarmth warmth;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.pill);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + index * 45),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final t = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey('warmth-option-${warmth.key}'),
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHigh,
              borderRadius: radius,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(warmth.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 7),
                Text(
                  warmth.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
