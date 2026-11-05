import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/bento_card.dart';
import '../../domain/ethiopian_pet.dart';
import '../../domain/pet_care_action.dart';
import '../../domain/shared_pet.dart';
import '../pet_visuals.dart';
import 'pet_avatar.dart';

class PetCard extends StatelessWidget {
  const PetCard({
    super.key,
    required this.pet,
    required this.now,
    required this.onCare,
    this.onOpen,
  });

  final SharedPet pet;
  final DateTime now;
  final ValueChanged<PetCareAction> onCare;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mood = pet.careMoodAt(now);
    final badgeIcon = mood.badgeIcon ?? Icons.pets_rounded;
    final companion = EthiopianPet.byId(pet.species);

    return Semantics(
      label:
          '${pet.name} the ${companion.commonName} is ${mood.label}. '
          'Happiness ${pet.happiness.round()} percent, level ${pet.level}.',
      child: BentoCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GestureDetector(
              onTap: onOpen,
              child: Tooltip(
                message: 'Meet ${pet.name}',
                child: PetAvatar(pet: companion, size: 92),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _LevelPill(level: pet.level),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: mood.label,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surfaceContainerHighest,
                          ),
                          child: Icon(
                            badgeIcon,
                            size: 13,
                            color: mood.badgeColor(scheme),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    mood.messageFor(pet.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                  _JoyBar(value: pet.happiness),
                  Row(
                    children: [
                      for (var i = 0; i < PetCareAction.values.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _CareButton(
                            action: PetCareAction.values[i],
                            petName: pet.name,
                            onTap: () => onCare(PetCareAction.values[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Lv $level',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: scheme.onPrimaryContainer, fontSize: 9.5),
      ),
    );
  }
}

class _JoyBar extends StatelessWidget {
  const _JoyBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.favorite_rounded, size: 13, color: scheme.primary),
        const SizedBox(width: 5),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (value / SharedPet.maxStat).clamp(0, 1),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '${value.round()}%',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 9.5),
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
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconFor(action),
                  size: 13,
                  color: _tintFor(action, scheme),
                ),
                const SizedBox(width: 3),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(fontSize: 9.5, color: scheme.onSurface),
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
