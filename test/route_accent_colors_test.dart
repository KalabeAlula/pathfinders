import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_colors.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/location/presentation/widgets/map_circle_view.dart';

CircleMember _member(String id) => CircleMember(
  profile: UserProfile(id: id, displayName: id, avatarColor: 0xFF8C5BA8),
  status: null,
);

void main() {
  final members = [_member('you'), _member('amir'), _member('bella')];

  test('the local member always takes the scheme primary', () {
    for (final scheme in [AppColors.lightScheme, AppColors.darkScheme]) {
      final colors = routeAccentColors(
        members: members,
        currentUserId: 'you',
        scheme: scheme,
      );

      expect(colors['you'], scheme.primary);
    }
  });

  test('peer colors are brighter on the night basemap', () {
    final light = routeAccentColors(
      members: members,
      currentUserId: 'you',
      scheme: AppColors.lightScheme,
    );
    final dark = routeAccentColors(
      members: members,
      currentUserId: 'you',
      scheme: AppColors.darkScheme,
    );

    for (final id in ['amir', 'bella']) {
      expect(
        dark[id]!.computeLuminance(),
        greaterThan(light[id]!.computeLuminance()),
      );
    }
    expect(dark['amir'], const Color(0xFF8FB6E8));
    expect(light['amir'], const Color(0xFF3F6FA8));
  });

  test('peer colors stay stable regardless of member order', () {
    final colors = routeAccentColors(
      members: members,
      currentUserId: 'you',
      scheme: AppColors.darkScheme,
    );
    final reversed = routeAccentColors(
      members: members.reversed.toList(),
      currentUserId: 'you',
      scheme: AppColors.darkScheme,
    );

    expect(reversed, colors);
  });
}
