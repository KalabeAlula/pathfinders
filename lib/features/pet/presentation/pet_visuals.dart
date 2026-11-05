import 'package:flutter/material.dart';

import '../domain/shared_pet.dart';

extension PetCareMoodVisuals on PetCareMood {
  String get label => switch (this) {
    PetCareMood.happy => 'Happy',
    PetCareMood.content => 'Content',
    PetCareMood.hungry => 'Hungry',
    PetCareMood.sleepy => 'Sleepy',
    PetCareMood.dirty => 'Needs a wash',
    PetCareMood.playing => 'Playing',
  };

  String messageFor(String name) => switch (this) {
    PetCareMood.happy => '$name is glowing — the whole crew showed up today.',
    PetCareMood.content => '$name is cozy. A little play would go a long way.',
    PetCareMood.hungry => '$name is staring at the snack drawer.',
    PetCareMood.sleepy => '$name is dozing. Maybe let the lights dim.',
    PetCareMood.dirty => '$name needs a little spa moment.',
    PetCareMood.playing => '$name is bouncing around — someone just played!',
  };

  IconData? get badgeIcon => switch (this) {
    PetCareMood.happy => Icons.auto_awesome_rounded,
    PetCareMood.content => null,
    PetCareMood.hungry => Icons.restaurant_rounded,
    PetCareMood.sleepy => Icons.bedtime_rounded,
    PetCareMood.dirty => Icons.water_drop_rounded,
    PetCareMood.playing => Icons.favorite_rounded,
  };

  Color badgeColor(ColorScheme scheme) => switch (this) {
    PetCareMood.happy => scheme.tertiary,
    PetCareMood.content => scheme.onSurfaceVariant,
    PetCareMood.hungry => const Color(0xFFD98548),
    PetCareMood.sleepy => const Color(0xFF7B83B8),
    PetCareMood.dirty => const Color(0xFF6C93A8),
    PetCareMood.playing => scheme.primary,
  };
}
