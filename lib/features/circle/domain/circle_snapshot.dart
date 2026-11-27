import '../../profile/domain/profile_details.dart';
import 'circle.dart';
import 'circle_member.dart';

class CircleSnapshot {
  const CircleSnapshot({required this.circle, required this.members});

  final Circle circle;
  final List<CircleMember> members;

  /// Returns a copy with [live] overlaid on the matching member's profile so
  /// edits in ProfileTab reflect across all tabs with zero delay.
  CircleSnapshot withLiveProfile(ProfileDetails? live) {
    if (live == null) return this;
    final updated = applyLiveProfile(members, live);
    if (identical(updated, members)) return this;
    return CircleSnapshot(circle: circle, members: updated);
  }

  static List<CircleMember> applyLiveProfile(
    List<CircleMember> members,
    ProfileDetails? live,
  ) {
    if (live == null) return members;
    var changed = false;
    final next = [
      for (final member in members)
        if (member.profile.id == live.userId &&
            (member.profile.displayName != live.displayName ||
                member.profile.avatarId != live.avatarId)) ...[
          (() {
            changed = true;
            return CircleMember(
              profile: member.profile.copyWith(
                displayName: live.displayName,
                avatarId: live.avatarId,
              ),
              status: member.status,
            );
          })(),
        ] else
          member,
    ];
    return changed ? next : members;
  }

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
