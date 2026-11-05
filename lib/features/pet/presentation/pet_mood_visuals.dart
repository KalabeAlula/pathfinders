import 'package:flutter/material.dart';

import '../domain/pet_mood.dart';

extension PetMoodVisuals on PetMood {
  String get label => switch (this) {
    PetMood.idle => 'Resting',
    PetMood.traveling => 'On the move',
    PetMood.celebrating => 'Celebrating',
    PetMood.sleeping => 'Sleeping',
  };

  String messageFor(String name) => switch (this) {
    PetMood.idle => '$name is keeping watch while the crew rests.',
    PetMood.traveling => '$name is leading the way to the destination.',
    PetMood.celebrating => '$name is bouncing — the crew made it!',
    PetMood.sleeping => '$name curled up for a cozy nap.',
  };

  IconData get badgeIcon => switch (this) {
    PetMood.idle => Icons.visibility_rounded,
    PetMood.traveling => Icons.directions_walk_rounded,
    PetMood.celebrating => Icons.auto_awesome_rounded,
    PetMood.sleeping => Icons.bedtime_rounded,
  };

  Color accent(ColorScheme scheme) => switch (this) {
    PetMood.idle => scheme.secondary,
    PetMood.traveling => scheme.primary,
    PetMood.celebrating => scheme.tertiary,
    PetMood.sleeping => const Color(0xFF7B83B8),
  };
}
