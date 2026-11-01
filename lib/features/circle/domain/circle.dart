/// A closed micro-group. The four-person ceiling is a product rule, so the
/// model enforces it instead of leaving it to screens to remember.
class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
    required this.createdAt,
  });

  static const int maxMembers = 4;

  final String id;
  final String name;
  final String inviteCode;
  final List<String> memberIds;
  final DateTime createdAt;

  bool get isFull => memberIds.length >= maxMembers;

  int get openSeats => maxMembers - memberIds.length;

  bool hasMember(String userId) => memberIds.contains(userId);
}
