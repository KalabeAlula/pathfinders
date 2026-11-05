import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/location/domain/member_status.dart';
import 'package:pathfinders/features/location/domain/privacy_mode.dart';
import 'package:pathfinders/features/location/presentation/widgets/map_circle_view.dart';
import 'package:pathfinders/features/navigation/application/navigation_state.dart';
import 'package:pathfinders/features/profile/domain/animal_avatar.dart';

UserProfile _profile({
  required String id,
  required String name,
  String? avatarId,
}) {
  return UserProfile(
    id: id,
    displayName: name,
    avatarColor: 0xFF8C5BA8,
    avatarId: avatarId,
  );
}

CircleMember _member(UserProfile profile) {
  return CircleMember(
    profile: profile,
    status: MemberStatus(
      userId: profile.id,
      location: const GeoPoint(latitude: 9.03, longitude: 38.74),
      batteryPercent: 72,
      isCharging: false,
      speedKph: 0,
      isOnline: true,
      privacyMode: PrivacyMode.exact,
      updatedAt: DateTime(2026, 11, 5, 9),
    ),
  );
}

void main() {
  test('every catalog avatar has a unique id and a shipped asset', () {
    final ids = AnimalAvatar.catalog.map((avatar) => avatar.id).toSet();
    expect(ids, hasLength(AnimalAvatar.catalog.length));

    for (final avatar in AnimalAvatar.catalog) {
      expect(avatar.id, startsWith('avatar_'));
      expect(avatar.name, isNotEmpty);
      expect(
        File(avatar.assetPath).existsSync(),
        isTrue,
        reason: '${avatar.id} points at a missing asset',
      );
    }
  });

  test('unknown or missing ids fall back to the wolf portrait', () {
    expect(AnimalAvatar.tryById('avatar_dragon'), isNull);
    expect(AnimalAvatar.tryById(null), isNull);
    expect(AnimalAvatar.byId('avatar_dragon').id, AnimalAvatar.fallbackId);
    expect(AnimalAvatar.byId(null).id, AnimalAvatar.fallbackId);
    expect(AnimalAvatar.assetFor(null), AnimalAvatar.wolf.assetPath);
  });

  test('map pins resolve each member avatar id to its catalog asset', () {
    final view = MapCircleView.from(
      members: [
        _member(
          _profile(id: 'u1', name: 'Kaleab', avatarId: 'avatar_lion'),
        ),
        _member(_profile(id: 'u2', name: 'Hana', avatarId: 'avatar_deer')),
        _member(_profile(id: 'u3', name: 'Meron', avatarId: 'avatar_owl')),
        // Rows written before avatars existed carry no id.
        _member(_profile(id: 'u4', name: 'Dawit')),
      ],
      currentUserId: 'u1',
      navigation: const NavigationState(),
      scheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE0A93E)),
    );

    final pins = {for (final pin in view.pins) pin.id: pin};

    expect(
      AnimalAvatar.assetFor(pins['u1']!.avatarId),
      'assets/avatars/lion.png',
    );
    expect(
      AnimalAvatar.assetFor(pins['u2']!.avatarId),
      'assets/avatars/deer.png',
    );
    expect(
      AnimalAvatar.assetFor(pins['u3']!.avatarId),
      'assets/avatars/owl.png',
    );
    expect(
      AnimalAvatar.assetFor(pins['u4']!.avatarId),
      'assets/avatars/wolf.png',
    );

    expect(pins['u1']!.isCurrentUser, isTrue);
    expect(pins['u2']!.isCurrentUser, isFalse);
  });
}
