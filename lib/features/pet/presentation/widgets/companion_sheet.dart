import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../circle/domain/group_type.dart';
import '../../domain/ethiopian_pet.dart';
import '../../domain/pet_mood.dart';
import '../../domain/shared_pet.dart';
import '../pet_mood_visuals.dart';
import '../pet_visuals.dart';
import 'animated_pet_sticker.dart';

Future<void> showCompanionCard(
  BuildContext context, {
  required EthiopianPet pet,
  required SharedPet state,
  required GroupType groupType,
  required DateTime now,
  PetMood mood = PetMood.idle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CompanionCard(
      pet: pet,
      state: state,
      groupType: groupType,
      now: now,
      mood: mood,
    ),
  );
}

/// Small profile for the group companion, opened from the badge or pet card.
class CompanionCard extends StatelessWidget {
  const CompanionCard({
    super.key,
    required this.pet,
    required this.state,
    required this.groupType,
    required this.now,
    this.mood = PetMood.idle,
  });

  final EthiopianPet pet;
  final SharedPet state;
  final GroupType groupType;
  final DateTime now;
  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final careMood = state.careMoodAt(now);
    final xpLeft = SharedPet.experiencePerLevel - state.xpIntoLevel;

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
                                state.name,
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
                          '${pet.amharicName} · ${mood.label} · '
                          '${careMood.label}',
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
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text(
                    'Level ${state.level}',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '$xpLeft XP to level ${state.level + 1}',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: state.levelProgress,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
