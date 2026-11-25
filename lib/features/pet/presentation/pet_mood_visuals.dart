import 'package:flutter/material.dart';

import '../domain/pet_mood.dart';

extension PetMoodVisuals on PetMood {
  String get label => switch (this) {
    PetMood.idle => 'Resting',
    PetMood.traveling => 'On the move',
    PetMood.celebrating => 'Celebrating',
    PetMood.sleeping => 'Sleeping',
    PetMood.hyped => 'Hyped up!',
    PetMood.curious => 'Curious',
    PetMood.hungry => 'Hungry',
    PetMood.loved => 'Feeling loved',
  };

  String get emoji => switch (this) {
    PetMood.idle => '😌',
    PetMood.traveling => '🚀',
    PetMood.celebrating => '🎉',
    PetMood.sleeping => '💤',
    PetMood.hyped => '⚡',
    PetMood.curious => '🔍',
    PetMood.hungry => '🍖',
    PetMood.loved => '🥰',
  };

  String messageFor(String name) => switch (this) {
    PetMood.idle => '$name is keeping watch while the crew rests.',
    PetMood.traveling => '$name is leading the way to the destination.',
    PetMood.celebrating => '$name is bouncing — the crew made it!',
    PetMood.sleeping => '$name curled up for a cozy nap.',
    PetMood.hyped => '$name is pumped — crew is buzzing!',
    PetMood.curious => '$name noticed something new happening.',
    PetMood.hungry => '$name is hungry — time to feed!',
    PetMood.loved => '$name is feeling all the love right now.',
  };

  IconData get badgeIcon => switch (this) {
    PetMood.idle => Icons.visibility_rounded,
    PetMood.traveling => Icons.directions_walk_rounded,
    PetMood.celebrating => Icons.auto_awesome_rounded,
    PetMood.sleeping => Icons.bedtime_rounded,
    PetMood.hyped => Icons.bolt_rounded,
    PetMood.curious => Icons.search_rounded,
    PetMood.hungry => Icons.restaurant_rounded,
    PetMood.loved => Icons.favorite_rounded,
  };

  Color accent(ColorScheme scheme) => switch (this) {
    PetMood.idle => scheme.secondary,
    PetMood.traveling => scheme.primary,
    PetMood.celebrating => scheme.tertiary,
    PetMood.sleeping => const Color(0xFF7B83B8),
    PetMood.hyped => const Color(0xFFE87A1E),
    PetMood.curious => const Color(0xFF5BA8A0),
    PetMood.hungry => const Color(0xFFD4572A),
    PetMood.loved => const Color(0xFFE0507A),
  };
}
