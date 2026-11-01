import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/circle/presentation/member_status_label.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/location/domain/member_status.dart';
import 'package:pathfinders/features/location/domain/privacy_mode.dart';

void main() {
  final now = DateTime(2026, 11, 1, 18);
  const profile = UserProfile(
    id: 'kaleab',
    displayName: 'Kaleab Tesfaye',
    avatarColor: 0xFFB86B4F,
  );

  MemberStatus status({
    DateTime? arrivedAt,
    double speedKph = 0,
    PrivacyMode privacyMode = PrivacyMode.exact,
    bool isOnline = true,
  }) {
    return MemberStatus(
      userId: profile.id,
      location: const GeoPoint(latitude: 9.0, longitude: 38.75),
      batteryPercent: 68,
      isCharging: true,
      speedKph: speedKph,
      isOnline: isOnline,
      privacyMode: privacyMode,
      updatedAt: now.subtract(const Duration(minutes: 4)),
      arrivedAt: arrivedAt,
    );
  }

  test('sheet copy describes a dwell naturally', () {
    final resting = status(
      arrivedAt: now.subtract(const Duration(hours: 2, minutes: 15)),
    );

    expect(describeMemberLocation(resting, now), 'Stopped for 2h 15m');
  });

  test('sheet copy avoids reading "for just arrived"', () {
    final fresh = status(arrivedAt: now.subtract(const Duration(seconds: 20)));
    final member = CircleMember(profile: profile, status: fresh);

    expect(describeMemberLocation(fresh, now), 'Just stopped');
    expect(describeMemberStatus(member, now), 'Just stopped');
  });

  test('sheet copy covers motion, privacy, and missing updates', () {
    expect(
      describeMemberLocation(status(speedKph: 14.4), now),
      'Moving at 14 km/h',
    );
    expect(
      describeMemberLocation(status(privacyMode: PrivacyMode.paused), now),
      'Location paused',
    );
    expect(describeMemberLocation(null, now), 'Waiting for the first update');
  });

  test('approximate sharing never leaks a place or dwell', () {
    expect(
      describeMemberLocation(
        status(
          privacyMode: PrivacyMode.approximate,
          arrivedAt: now.subtract(const Duration(hours: 1)),
        ),
        now,
      ),
      'Sharing an approximate area',
    );
  });

  test('offline copy falls back to last seen', () {
    expect(
      describeMemberLocation(status(isOnline: false), now),
      'Last seen 4m ago',
    );
  });

  test('a member with no status says so', () {
    const member = CircleMember(profile: profile, status: null);

    expect(describeMemberStatus(member, now), 'No updates yet');
  });
}
