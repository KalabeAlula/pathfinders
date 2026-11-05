import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/application/clock_provider.dart';
import '../../../circle/application/circle_providers.dart';
import '../../../circle/domain/circle.dart';
import '../../application/pet_providers.dart';
import '../../domain/pet_care_action.dart';
import '../../../circle/domain/group_type.dart';
import '../../domain/ethiopian_pet.dart';
import '../../domain/pet_mood.dart';
import '../../domain/shared_pet.dart';
import '../pet_mood_visuals.dart';
import '../pet_visuals.dart';
import 'animated_pet_sticker.dart';

Future<void> showCompanionCard(
  BuildContext context, {
  required String circleId,
  required String currentUserId,
  required EthiopianPet pet,
  required GroupType groupType,
  PetMood mood = PetMood.idle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CompanionCard(
      circleId: circleId,
      currentUserId: currentUserId,
      pet: pet,
      groupType: groupType,
      mood: mood,
    ),
  );
}

/// The group companion's profile and care controls. State comes from the
/// live circle snapshot, so a care tap shows up as soon as the row lands.
class CompanionCard extends ConsumerWidget {
  const CompanionCard({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.pet,
    required this.groupType,
    this.mood = PetMood.idle,
  });

  final String circleId;
  final String currentUserId;
  final EthiopianPet pet;
  final GroupType groupType;
  final PetMood mood;

  Circle? _circleOf(WidgetRef ref) {
    final circle = ref.watch(circleSnapshotProvider(currentUserId)).value?.circle;
    if (circle == null || circle.id != circleId) return null;
    return circle;
  }

  Future<void> _care(
    BuildContext context,
    WidgetRef ref,
    PetCareAction action,
  ) async {
    try {
      await ref.read(petRepositoryProvider(circleId)).care(action);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach your companion.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(appClockProvider).value ?? DateTime.now();
    final circle = _circleOf(ref);
    final state = circle == null ? null : SharedPet.fromCircle(circle);
    final petState = state?.decayed(now.difference(state.updatedAt), now);
    final name = petState?.name ?? pet.defaultName;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  AnimatedPetSticker(pet: pet, mood: mood, size: 84),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 7),
                            _Pill(
                              label: groupType.label.toUpperCase(),
                              background: scheme.primaryContainer,
                              foreground: scheme.onPrimaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pet.commonName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pet.amharicName} · ${mood.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _HabitatLine(habitat: pet.habitat),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 17,
                      color: scheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        pet.funFact,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (petState != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _StatBar(
                  icon: Icons.favorite_rounded,
                  label: petState.careMoodAt(now).label,
                  value: petState.happiness,
                  color: scheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'Level ${petState.level}',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${SharedPet.experiencePerLevel - petState.xpIntoLevel} '
                      'XP to level ${petState.level + 1}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: petState.levelProgress,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    for (var i = 0; i < PetCareAction.values.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CareButton(
                          action: PetCareAction.values[i],
                          petName: petState.name,
                          onTap: () =>
                              _care(context, ref, PetCareAction.values[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (value / SharedPet.maxStat).clamp(0, 1),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '${value.round()}%',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CareButton extends StatelessWidget {
  const _CareButton({
    required this.action,
    required this.petName,
    required this.onTap,
  });

  final PetCareAction action;
  final String petName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '${action.label} $petName',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: onTap,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconFor(action),
                  size: 16,
                  color: _tintFor(action, scheme),
                ),
                const SizedBox(width: 5),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(PetCareAction action) => switch (action) {
  PetCareAction.feed => Icons.restaurant_rounded,
  PetCareAction.clean => Icons.water_drop_rounded,
  PetCareAction.play => Icons.sports_esports_rounded,
};

Color _tintFor(PetCareAction action, ColorScheme scheme) => switch (action) {
  PetCareAction.feed => const Color(0xFFD98548),
  PetCareAction.clean => const Color(0xFF6C93A8),
  PetCareAction.play => scheme.primary,
};

class _HabitatLine extends StatelessWidget {
  const _HabitatLine({required this.habitat});

  final String habitat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.landscape_rounded, size: 17, color: scheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Native to $habitat',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground, fontSize: 8.5, letterSpacing: 0.6),
      ),
    );
  }
}
