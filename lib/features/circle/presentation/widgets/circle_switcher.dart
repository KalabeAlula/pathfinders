import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../application/circle_providers.dart';
import '../../domain/circle_failure.dart';
import '../../domain/circle_summary.dart';
import 'group_type_badge.dart';

/// The bottom strip of circles: compact pills that switch the active circle,
/// with a trailing button to create or join another one.
class CircleSwitcher extends ConsumerWidget {
  const CircleSwitcher({
    super.key,
    required this.userId,
    required this.onAdd,
  });

  final String userId;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final circles = ref.watch(circlesProvider(userId));
    final activeId = ref.watch(activeCircleControllerProvider(userId));

    return SizedBox(
      height: 48,
      child: circles.when(
        data: (items) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return _AddButton(onTap: onAdd);
            }
            final circle = items[index];
            final active = circle.id == activeId;
            return _CirclePill(
              key: ValueKey('circle-card-${circle.id}'),
              circle: circle,
              active: active,
              onTap: active
                  ? null
                  : () => ref
                        .read(activeCircleControllerProvider(userId).notifier)
                        .select(circle.id),
            );
          },
        ),
        loading: () => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            for (var i = 0; i < 2; i++)
              Container(
                width: 132,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            _AddButton(onTap: onAdd),
          ],
        ),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  error is CircleFailure
                      ? error.message
                      : 'Could not load your circles.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(circlesProvider(userId)),
                child: const Text('Retry'),
              ),
              _AddButton(onTap: onAdd),
            ],
          ),
        ),
      ),
    );
  }
}

class _CirclePill extends StatelessWidget {
  const _CirclePill({
    super.key,
    required this.circle,
    required this.active,
    required this.onTap,
  });

  final CircleSummary circle;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.pill);

    return Semantics(
      button: true,
      selected: active,
      label: 'Switch to ${circle.name}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(maxWidth: 216),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active
                  ? scheme.primaryContainer.withValues(alpha: 0.42)
                  : scheme.surfaceContainerLow,
              borderRadius: radius,
              border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
                width: active ? 1.6 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  groupTypeIcon(circle.type),
                  size: 15,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    circle.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: active ? scheme.onPrimaryContainer : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· ${circle.memberCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: active
                        ? scheme.onPrimaryContainer.withValues(alpha: 0.75)
                        : scheme.onSurfaceVariant,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 5),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: scheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Create or join a circle',
      child: Align(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey('circle-hub-add'),
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 22,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
