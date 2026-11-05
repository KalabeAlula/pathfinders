import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/core/application/clock_provider.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/circle/domain/circle_summary.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/circle/presentation/circle_tab.dart';
import 'package:pathfinders/features/location/application/telemetry_providers.dart';
import 'package:pathfinders/features/location/domain/device_telemetry.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/location/domain/member_status.dart';
import 'package:pathfinders/features/location/domain/privacy_mode.dart';
import 'package:pathfinders/features/pet/application/pet_mood_providers.dart';
import 'package:pathfinders/features/pet/domain/pet_mood.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 11, 5, 18);

  const kaleab = UserProfile(
    id: 'u1',
    displayName: 'Kaleab Tesfaye',
    avatarColor: 0xFFB86B4F,
  );
  const liya = UserProfile(
    id: 'u2',
    displayName: 'Liya Bekele',
    avatarColor: 0xFF7C8C6B,
  );

  MemberStatus status(
    String userId, {
    int battery = 84,
    bool charging = false,
  }) {
    return MemberStatus(
      userId: userId,
      location: const GeoPoint(latitude: 9.0, longitude: 38.75),
      batteryPercent: battery,
      isCharging: charging,
      speedKph: 0,
      isOnline: true,
      privacyMode: PrivacyMode.exact,
      updatedAt: now,
    );
  }

  final snapshot = CircleSnapshot(
    circle: Circle(
      id: 'c1',
      name: 'Trail Crew',
      inviteCode: 'PF-9K2Q',
      memberIds: const ['u1', 'u2'],
      createdAt: now,
      type: GroupType.friends,
      createdBy: 'u1',
      petId: 'gelada',
      petName: 'Desta',
    ),
    members: [
      CircleMember(
        profile: kaleab,
        status: status('u1', battery: 84, charging: true),
      ),
      CircleMember(profile: liya, status: status('u2', battery: 12)),
    ],
  );

  final summaries = [
    CircleSummary(
      id: 'c1',
      name: 'Trail Crew',
      type: GroupType.friends,
      memberCount: 2,
      createdAt: now,
      petId: 'gelada',
      petName: 'Desta',
    ),
  ];

  Future<void> pumpTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appClockProvider.overrideWith((_) => Stream.value(now)),
          circlesProvider('u1').overrideWith((_) => Stream.value(summaries)),
          petMoodProvider('c1').overrideWithValue(PetMood.idle),
          telemetryControllerProvider('u1').overrideWithValue(
            const TelemetryState(permission: TelemetryPermission.granted),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: CircleTab(snapshot: snapshot, currentUserId: 'u1'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the circle, companion, and member telemetry', (
    tester,
  ) async {
    await pumpTab(tester);

    expect(find.text('Your groups'), findsOneWidget);
    expect(find.text('1 group · sharing with Trail Crew'), findsOneWidget);
    expect(find.text('Your group'), findsOneWidget);
    // The hub card and the detail header both name the active circle.
    expect(find.text('Trail Crew'), findsNWidgets(2));
    expect(find.text('2 of 4 members · Friends'), findsOneWidget);
    // The carousel badge and the companion card badge.
    expect(find.text('FRIENDS'), findsNWidgets(2));

    expect(find.text('Desta the Gelada'), findsOneWidget);
    expect(find.textContaining('Level 1'), findsOneWidget);
    expect(find.text('2 open seats'), findsOneWidget);

    expect(find.text('PF-9K2Q'), findsOneWidget);
    expect(
      find.text('Anyone with this code can join Trail Crew.'),
      findsOneWidget,
    );

    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Kaleab'), findsOneWidget);
    expect(find.text('you'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(find.text('Liya'), findsOneWidget);

    expect(find.text('84%'), findsOneWidget);
    expect(find.text('12%'), findsOneWidget);
  });

  testWidgets('copying the invite code confirms with a snackbar', (
    tester,
  ) async {
    final clipboard = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpTab(tester);

    await tester.tap(find.byKey(const ValueKey('invite-copy')));
    await tester.pump();
    await tester.pump();

    expect(clipboard, ['PF-9K2Q']);
    expect(find.text('Invite code PF-9K2Q copied.'), findsOneWidget);
  });
}
