import '../../pet/domain/ethiopian_pet.dart';
import 'group_type.dart';

/// The lightweight row used by the group switcher: enough to show a name, a
/// type badge, a seat count, and the companion without loading every member.
class CircleSummary {
  const CircleSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.memberCount,
    required this.createdAt,
    this.petId = 'lovebird',
    this.petName = 'Momo',
    this.petLevel = 1,
  });

  final String id;
  final String name;
  final GroupType type;
  final int memberCount;
  final DateTime createdAt;
  final String petId;
  final String petName;
  final int petLevel;

  bool get isFull => memberCount >= type.capacity;

  int get openSeats => type.capacity - memberCount;

  factory CircleSummary.fromRow(
    Map<String, dynamic> row, {
    required int memberCount,
  }) {
    final type = GroupType.fromDb(row['group_type']);
    final petId = EthiopianPet.tryById(_text(row['pet_id'], ''))?.id ??
        EthiopianPet.tryById(_text(row['pet_species'], ''))?.id ??
        type.defaultPet.id;
    return CircleSummary(
      id: row['id'] as String,
      name: row['name'] as String,
      type: type,
      memberCount: memberCount,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      petId: petId,
      petName: _text(row['pet_name'], EthiopianPet.byId(petId).defaultName),
      petLevel: _positiveInt(row['pet_level']),
    );
  }

  static String _text(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  static int _positiveInt(Object? value) {
    final level = value is num ? value.toInt() : 1;
    return level < 1 ? 1 : level;
  }
}
