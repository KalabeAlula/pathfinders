import 'circle.dart';
import 'circle_member.dart';

class CircleSnapshot {
  const CircleSnapshot({required this.circle, required this.members});

  final Circle circle;
  final List<CircleMember> members;

  CircleMember? memberById(String userId) {
    for (final member in members) {
      if (member.profile.id == userId) return member;
    }
    return null;
  }

  List<CircleMember> get sharingLocation => members
      .where((member) => member.status?.hasLocation ?? false)
      .toList(growable: false);

  int get onlineCount =>
      members.where((member) => member.status?.isOnline ?? false).length;
}
