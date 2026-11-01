import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';

const circleId = 'circle-test';
const kaleabId = 'user-kaleab';
const hanaId = 'user-hana';
const memberIds = [kaleabId, hanaId, 'user-sofi', 'user-momo'];

void main() {
  group('Circle', () {
    Circle build(List<String> ids) => Circle(
          id: circleId,
          name: 'Bole Crew',
          inviteCode: 'MOMO24',
          memberIds: ids,
          createdAt: DateTime(2025, 3, 14),
        );

    test('a four-person circle is full', () {
      final circle = build(memberIds);

      expect(circle.isFull, isTrue);
      expect(circle.openSeats, 0);
      expect(Circle.maxMembers, 4);
    });

    test('open seats count down as members join', () {
      final circle = build([kaleabId, hanaId]);

      expect(circle.isFull, isFalse);
      expect(circle.openSeats, 2);
    });
  });

  test('snapshot can find a member by id', () {
    const profile = UserProfile(
      id: kaleabId,
      displayName: 'Kaleab Tesfaye',
      avatarColor: 0xFFB86B4F,
    );
    final snapshot = CircleSnapshot(
      circle: Circle(
        id: circleId,
        name: 'Bole Crew',
        inviteCode: 'MOMO24',
        memberIds: const [kaleabId],
        createdAt: DateTime(2025, 3, 14),
      ),
      members: const [CircleMember(profile: profile, status: null)],
    );

    expect(snapshot.memberById(kaleabId)?.profile.displayName, 'Kaleab Tesfaye');
    expect(snapshot.memberById('missing'), isNull);
  });

  test('profiles derive initials safely', () {
    expect(
      const UserProfile(id: '1', displayName: 'Kaleab', avatarColor: 0)
          .initials,
      'K',
    );
    expect(
      const UserProfile(id: '2', displayName: 'Kaleab Tesfaye', avatarColor: 0)
          .initials,
      'KT',
    );
    expect(
      const UserProfile(id: '3', displayName: '   ', avatarColor: 0).initials,
      '?',
    );
  });
}
