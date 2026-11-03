import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/circle/domain/circle_summary.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
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

  group('Group types', () {
    Circle typed(GroupType type, List<String> ids) => Circle(
      id: circleId,
      name: 'Bole Crew',
      inviteCode: 'MOMO24',
      memberIds: ids,
      createdAt: DateTime(2025, 3, 14),
      type: type,
    );

    test('caps match the database contract', () {
      expect(GroupType.couple.capacity, 2);
      expect(GroupType.friends.capacity, 4);
      expect(GroupType.family.capacity, 6);
      expect(GroupType.fromDb('family'), GroupType.family);
      expect(GroupType.fromDb(null), GroupType.friends);
      expect(GroupType.fromDb('unknown'), GroupType.friends);
    });

    test('a couple fills at two and a family opens six seats', () {
      expect(typed(GroupType.couple, [kaleabId, hanaId]).isFull, isTrue);
      expect(typed(GroupType.couple, [kaleabId]).openSeats, 1);
      expect(typed(GroupType.family, memberIds).openSeats, 2);
      expect(typed(GroupType.family, memberIds).isFull, isFalse);
    });

    test('legacy circles keep the four-seat default', () {
      final circle = Circle(
        id: circleId,
        name: 'Bole Crew',
        inviteCode: 'MOMO24',
        memberIds: memberIds,
        createdAt: DateTime(2025, 3, 14),
      );

      expect(circle.type, GroupType.friends);
      expect(circle.capacity, Circle.maxMembers);
      expect(circle.isFull, isTrue);
    });

    test('pet metadata parses from a circle row', () {
      final circle = Circle.fromRow(
        {
          'id': circleId,
          'name': 'Bole Crew',
          'invite_code': 'MOMO24',
          'group_type': 'family',
          'pet_id': 'lion',
          'pet_name': 'Biscuit',
          'pet_level': 5,
          'pet_mood': 'happy',
          'created_at': '2025-03-14T00:00:00Z',
        },
        memberIds: [kaleabId],
      );

      expect(circle.type, GroupType.family);
      expect(circle.petId, 'lion');
      expect(circle.petName, 'Biscuit');
      expect(circle.petLevel, 5);
      expect(circle.petMood, 'happy');
    });

    test('pet care stats parse with safe fallbacks', () {
      final circle = Circle.fromRow({
        'id': circleId,
        'name': 'Bole Crew',
        'invite_code': 'MOMO24',
        'pet_experience': 240,
        'pet_hunger': 62.5,
        'pet_energy': 140,
        'pet_hygiene': -9,
        'pet_happiness': 76,
        'pet_last_action': 'feed',
        'pet_last_action_at': '2025-03-14T06:00:00Z',
        'pet_updated_at': '2025-03-14T06:00:00Z',
        'created_at': '2025-03-14T00:00:00Z',
      }, memberIds: const []);

      expect(circle.petExperience, 240);
      expect(circle.petHunger, 62.5);
      expect(circle.petEnergy, 100);
      expect(circle.petHygiene, 0);
      expect(circle.petHappiness, 76);
      expect(circle.petLastAction, 'feed');
      expect(circle.petLastActionAt, isNotNull);
      expect(circle.petUpdatedAt, isNotNull);
    });

    test('rows written before group types fall back safely', () {
      final circle = Circle.fromRow({
        'id': circleId,
        'name': 'Bole Crew',
        'invite_code': 'MOMO24',
        'created_at': '2025-03-14T00:00:00Z',
      }, memberIds: const []);

      expect(circle.type, GroupType.friends);
      expect(circle.petId, 'gelada');
      expect(circle.petName, 'Chele');
      expect(circle.petLevel, 1);
      expect(circle.petMood, 'content');
      expect(circle.petExperience, 0);
      expect(circle.petHunger, 70);
      expect(circle.petEnergy, 70);
      expect(circle.petHygiene, 70);
      expect(circle.petHappiness, 70);
      expect(circle.petLastAction, isNull);
      expect(circle.petUpdatedAt, isNull);
    });

    test('the switcher summary reports seats and the companion', () {
      final summary = CircleSummary.fromRow({
        'id': circleId,
        'name': 'Bole Crew',
        'group_type': 'couple',
        'pet_id': 'ethiopian_wolf',
        'pet_name': 'Rusty',
        'pet_level': 2,
        'created_at': '2025-03-14T00:00:00Z',
      }, memberCount: 2);

      expect(summary.type, GroupType.couple);
      expect(summary.isFull, isTrue);
      expect(summary.openSeats, 0);
      expect(summary.petId, 'ethiopian_wolf');
      expect(summary.petName, 'Rusty');
      expect(summary.petLevel, 2);
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

    expect(
      snapshot.memberById(kaleabId)?.profile.displayName,
      'Kaleab Tesfaye',
    );
    expect(snapshot.memberById('missing'), isNull);
  });

  test('profiles derive initials safely', () {
    expect(
      const UserProfile(
        id: '1',
        displayName: 'Kaleab',
        avatarColor: 0,
      ).initials,
      'K',
    );
    expect(
      const UserProfile(
        id: '2',
        displayName: 'Kaleab Tesfaye',
        avatarColor: 0,
      ).initials,
      'KT',
    );
    expect(
      const UserProfile(id: '3', displayName: '   ', avatarColor: 0).initials,
      '?',
    );
  });
}
