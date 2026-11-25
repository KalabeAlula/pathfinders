enum PetCareAction {
  feed(
    label: 'Feed',
    hunger: 34,
    energy: 15, // CHANGED: +15 (was +2)
    hygiene: -5,
    happiness: 5,
    experience: 8,
  ),
  clean(
    label: 'Clean',
    hunger: 0,
    energy: 0, // CHANGED: 0 (was -2)
    hygiene: 38,
    happiness: 7,
    experience: 6,
  ),
  play(
    label: 'Play',
    hunger: -8,
    energy: -5, // CHANGED: -5 (was -10)
    hygiene: -4,
    happiness: 20,
    experience: 10,
  );

  const PetCareAction({
    required this.label,
    required this.hunger,
    required this.energy,
    required this.hygiene,
    required this.happiness,
    required this.experience,
  });

  final String label;
  final double hunger;
  final double energy;
  final double hygiene;
  final double happiness;
  final int experience;
}
