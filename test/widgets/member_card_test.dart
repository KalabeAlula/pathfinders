import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/circle/presentation/widgets/member_card.dart';
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
  const studio = GeoPoint(latitude: 9.0, longitude: 38.75);

  MemberStatus status({
    PrivacyMode privacyMode = PrivacyMode.exact,
    DateTime? arrivedAt,
    int? batteryPercent = 68,
  }) {
    return MemberStatus(
      userId: profile.id,
      location: studio,
      batteryPercent: batteryPercent,
      isCharging: true,
      speedKph: 0,
      isOnline: true,
      privacyMode: privacyMode,
      updatedAt: now,
      arrivedAt: arrivedAt,
    );
  }

  Future<void> pumpCard(WidgetTester tester, MemberStatus telemetry) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 116,
              child: MemberCard(
                member: CircleMember(profile: profile, status: telemetry),
                isCurrentUser: true,
                now: now,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows name, battery, and dwell time', (tester) async {
    await pumpCard(
      tester,
      status(arrivedAt: now.subtract(const Duration(hours: 2, minutes: 15))),
    );

    expect(find.text('Kaleab'), findsOneWidget);
    expect(find.text('you'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('Stopped · 2h 15m'), findsOneWidget);
  });

  testWidgets('paused members show no location copy', (tester) async {
    await pumpCard(
      tester,
      status(privacyMode: PrivacyMode.paused),
    );

    expect(find.text('Location paused'), findsOneWidget);
  });

  testWidgets('a missing battery reading is not shown as 0%', (tester) async {
    await pumpCard(tester, status(batteryPercent: null));

    expect(find.text('0%'), findsNothing);
    expect(find.byIcon(Icons.battery_unknown_rounded), findsOneWidget);
  });
}
