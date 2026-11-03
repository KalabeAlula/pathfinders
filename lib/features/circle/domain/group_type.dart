import '../../pet/domain/ethiopian_pet.dart';

/// The three kinds of group, each with its own hard seat ceiling.
///
/// [capacity] mirrors `public.circle_capacity` in the database; the database
/// stays authoritative and rejects an over-cap join even if a client drifts.
enum GroupType {
  couple(
    dbValue: 'couple',
    label: 'Couple',
    capacity: 2,
    blurb: 'For the two of you, and everything you share.',
    petIds: ['lovebird', 'ethiopian_wolf'],
  ),
  friends(
    dbValue: 'friends',
    label: 'Friends',
    capacity: 4,
    blurb: 'The crew you make plans with and actually keep them.',
    petIds: ['gelada', 'bale_monkey'],
  ),
  family(
    dbValue: 'family',
    label: 'Family',
    capacity: 6,
    blurb: 'A wider table for the people who always show up.',
    petIds: ['walia_ibex', 'lion'],
  );

  const GroupType({
    required this.dbValue,
    required this.label,
    required this.capacity,
    required this.blurb,
    required this.petIds,
  });

  final String dbValue;
  final String label;
  final int capacity;
  final String blurb;
  final List<String> petIds;

  List<EthiopianPet> get pets => [
        for (final id in petIds) EthiopianPet.byId(id),
      ];

  EthiopianPet get defaultPet => pets.first;

  /// Rows created before group types existed carry the `friends` default.
  static const fallback = GroupType.friends;

  static GroupType fromDb(Object? value) {
    for (final type in values) {
      if (type.dbValue == value) return type;
    }
    return fallback;
  }
}
