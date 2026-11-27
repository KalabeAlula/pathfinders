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
  test('every catalog avatar has a unique id, shipped PNG, and WebP URL', () {
    expect(AnimalAvatar.catalog, hasLength(23));
    final ids = AnimalAvatar.catalog.map((avatar) => avatar.id).toSet();
    expect(ids, hasLength(AnimalAvatar.catalog.length));

    for (final avatar in AnimalAvatar.catalog) {
      expect(avatar.id, isNotEmpty);
      expect(avatar.name, isNotEmpty);
      expect(avatar.animatedUrl, isNotNull);
      expect(avatar.animatedUrl, endsWith('${avatar.id}.webp'));
      expect(
        File(avatar.assetPath).existsSync(),
        isTrue,
        reason: '${avatar.id} points at a missing asset',
      );
    }
  });

  test('unknown or missing ids fall back to cuddleBear, legacy ids map cleanly', () {
    expect(AnimalAvatar.tryById('avatar_dragon'), isNull);
    expect(AnimalAvatar.tryById(null), isNull);
    expect(AnimalAvatar.byId('avatar_dragon').id, AnimalAvatar.fallbackId);
    expect(AnimalAvatar.byId(null).id, AnimalAvatar.fallbackId);
    expect(AnimalAvatar.assetFor(null), AnimalAvatar.cuddleBear.assetPath);

    // Legacy DB ids map to upgraded animated avatars.
    final mappedWolf = AnimalAvatar.tryById('avatar_wolf');
    expect(mappedWolf, isNotNull);
    expect(mappedWolf!.animatedUrl, isNotNull);
    expect(mappedWolf.assetPath, startsWith('assets/avatars/converted/'));
  });

  test('map pins resolve each member avatar id to its catalog asset', () {
    final view = MapCircleView.from(
      members: [
        _member(
          _profile(id: 'u1', name: 'Kaleab', avatarId: 'party_king'),
        ),
        _member(_profile(id: 'u2', name: 'Hana', avatarId: 'avatar_deer')),
        _member(_profile(id: 'u3', name: 'Meron', avatarId: 'ice_monk')),
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
      AnimalAvatar.partyKing.assetPath,
    );
    expect(
      AnimalAvatar.assetFor(pins['u2']!.avatarId),
      AnimalAvatar.scout.assetPath,
    );
    expect(
      AnimalAvatar.assetFor(pins['u3']!.avatarId),
      AnimalAvatar.iceMonk.assetPath,
    );
    expect(
      AnimalAvatar.assetFor(pins['u4']!.avatarId),
      AnimalAvatar.cuddleBear.assetPath,
    );

    expect(pins['u1']!.isCurrentUser, isTrue);
    expect(pins['u2']!.isCurrentUser, isFalse);
  });
}
