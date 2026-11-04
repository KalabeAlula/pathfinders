import '../../pet/domain/ethiopian_pet.dart';
import 'group_type.dart';

/// A closed micro-group. Seat ceilings depend on the group type and are
/// enforced by the database; the model keeps screens honest with the same
/// numbers.
class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
    required this.createdAt,
    this.type = GroupType.friends,
    this.createdBy,
    this.petId = 'lovebird',
    this.petName = 'Momo',
    this.petLevel = 1,
    this.petMood = 'content',
    this.petExperience = 0,
    this.petHunger = 70,
    this.petEnergy = 70,
    this.petHygiene = 70,
    this.petHappiness = 70,
    this.petLastAction,
    this.petLastActionAt,
    this.petUpdatedAt,
  });

  /// The historical four-seat ceiling, kept for callers that predate group
  /// types. New code should use [capacity].
  static const int maxMembers = 4;

  final String id;
  final String name;
  final String inviteCode;
  final List<String> memberIds;
  final DateTime createdAt;
  final GroupType type;

  /// Null when the creator's profile has since been removed.
  final String? createdBy;
  final String petId;
  final String petName;
  final int petLevel;
  final String petMood;
  final int petExperience;
  final double petHunger;
  final double petEnergy;
  final double petHygiene;
  final double petHappiness;
  final String? petLastAction;
  final DateTime? petLastActionAt;
  final DateTime? petUpdatedAt;

  int get capacity => type.capacity;

  bool get isFull => memberIds.length >= capacity;

  int get openSeats => capacity - memberIds.length;

  bool hasMember(String userId) => memberIds.contains(userId);

  factory Circle.fromRow(
    Map<String, dynamic> row, {
    required List<String> memberIds,
  }) {
    final type = GroupType.fromDb(row['group_type']);
    final petId =
        EthiopianPet.tryById(_optionalText(row['pet_id']))?.id ??
        EthiopianPet.tryById(_optionalText(row['pet_species']))?.id ??
        type.defaultPet.id;
    return Circle(
      id: row['id'] as String,
      name: row['name'] as String,
      inviteCode: row['invite_code'] as String? ?? '',
      memberIds: memberIds,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      type: type,
      createdBy: _optionalText(row['created_by']),
      petId: petId,
      petName: _text(row['pet_name'], EthiopianPet.byId(petId).defaultName),
      petLevel: _positiveInt(row['pet_level']),
      petMood: _text(row['pet_mood'], 'content'),
      petExperience: _nonNegativeInt(row['pet_experience']),
      petHunger: _stat(row['pet_hunger']),
      petEnergy: _stat(row['pet_energy']),
      petHygiene: _stat(row['pet_hygiene']),
      petHappiness: _stat(row['pet_happiness']),
      petLastAction: _optionalText(row['pet_last_action']),
      petLastActionAt: _optionalDate(row['pet_last_action_at']),
      petUpdatedAt: _optionalDate(row['pet_updated_at']),
    );
  }

  static String _text(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  static String? _optionalText(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  static int _positiveInt(Object? value) {
    final level = value is num ? value.toInt() : 1;
    return level < 1 ? 1 : level;
  }

  static int _nonNegativeInt(Object? value) {
    final amount = value is num ? value.toInt() : 0;
    return amount < 0 ? 0 : amount;
  }

  static double _stat(Object? value) {
    final stat = value is num ? value.toDouble() : 70.0;
    return stat.clamp(0, 100).toDouble();
  }

  static DateTime? _optionalDate(Object? value) {
    if (value is! String) return null;
    return DateTime.parse(value).toLocal();
  }
}
