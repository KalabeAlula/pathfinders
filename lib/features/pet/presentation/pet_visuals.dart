import 'package:flutter/material.dart';

import '../domain/shared_pet.dart';

extension PetMoodVisuals on PetMood {
  String get label => switch (this) {
        PetMood.happy => 'Happy',
        PetMood.content => 'Content',
        PetMood.hungry => 'Hungry',
        PetMood.sleepy => 'Sleepy',
        PetMood.dirty => 'Needs a wash',
        PetMood.playing => 'Playing',
      };

  String messageFor(String name) => switch (this) {
        PetMood.happy => '$name is glowing — the whole crew showed up today.',
        PetMood.content => '$name is cozy. A little play would go a long way.',
        PetMood.hungry => '$name is staring at the snack drawer.',
        PetMood.sleepy => '$name is dozing. Maybe let the lights dim.',
        PetMood.dirty => '$name needs a little spa moment.',
        PetMood.playing => '$name is bouncing around — someone just played!',
      };

  IconData? get badgeIcon => switch (this) {
        PetMood.happy => Icons.auto_awesome_rounded,
        PetMood.content => null,
        PetMood.hungry => Icons.restaurant_rounded,
        PetMood.sleepy => Icons.bedtime_rounded,
        PetMood.dirty => Icons.water_drop_rounded,
        PetMood.playing => Icons.favorite_rounded,
      };

  Color badgeColor(ColorScheme scheme) => switch (this) {
        PetMood.happy => scheme.tertiary,
        PetMood.content => scheme.onSurfaceVariant,
        PetMood.hungry => const Color(0xFFD98548),
        PetMood.sleepy => const Color(0xFF7B83B8),
        PetMood.dirty => const Color(0xFF6C93A8),
        PetMood.playing => scheme.primary,
      };
}
