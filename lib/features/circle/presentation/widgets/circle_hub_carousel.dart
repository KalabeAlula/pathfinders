import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../pet/domain/ethiopian_pet.dart';
import '../../../pet/domain/pet_mood.dart';
import '../../../pet/presentation/widgets/animated_pet_sticker.dart';
import '../../application/circle_providers.dart';
import '../../domain/circle_failure.dart';
import '../../domain/circle_summary.dart';
import 'group_type_badge.dart';

/// The horizontal roster of every circle the member belongs to, with the
/// active one outlined in primary and a trailing add card.
class CircleHubCarousel extends ConsumerWidget {
  const CircleHubCarousel({
    super.key,
    required this.userId,
    required this.activeMood,
    required this.onAdd,
  });

  final String userId;

  /// Mood of the active circle, so its mini sticker matches the big one.
  final PetMood activeMood;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final circles = ref.watch(circlesProvider(userId));
    final activeId = ref.watch(activeCircleControllerProvider(userId));

    return SizedBox(
      height: 104,
      child: circles.when(
        data: (items) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return _AddCard(onTap: onAdd);
            }
            final circle = items[index];
            final active = circle.id == activeId;
            return _CircleCard(
              key: ValueKey('circle-card-${circle.id}'),
              circle: circle,
              active: active,
              mood: active ? activeMood : PetMood.idle,
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
                width: 148,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
              ),
            _AddCard(onTap: onAdd),
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
                      : 'Could not load your groups.',
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
              _AddCard(onTap: onAdd),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({
    super.key,
    required this.circle,
    required this.active,
    required this.mood,
    required this.onTap,
  });

  final CircleSummary circle;
  final bool active;
  final PetMood mood;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.tile);
    final companion = EthiopianPet.byId(circle.petId);

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
            width: 148,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // The whole card switches circles; the sticker must not
                    // swallow that tap with its own reaction.
                    IgnorePointer(
                      child: AnimatedPetSticker(
                        pet: companion,
                        mood: mood,
                        size: 28,
                        showParticles: false,
                      ),
                    ),
                    const Spacer(),
                    if (active)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  circle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GroupTypeBadge(type: circle.type, showIcon: false),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${circle.memberCount} of '
                        '${circle.type.capacity}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.tile);

    return Semantics(
      button: true,
      label: 'Create or join a group',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('circle-hub-add'),
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            width: 82,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.6),
              borderRadius: radius,
              border: Border.all(
                color: scheme.outlineVariant,
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add or join',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
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
