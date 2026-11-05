import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/core/application/clock_provider.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/data/active_circle_store.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/circle/domain/circle_summary.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/circle/presentation/circle_tab.dart';
import 'package:pathfinders/features/location/application/telemetry_providers.dart';
import 'package:pathfinders/features/location/domain/device_telemetry.dart';
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

  final snapshot = CircleSnapshot(
    circle: Circle(
      id: 'c1',
      name: 'Trail Crew',
      inviteCode: 'PF-9K2Q',
      memberIds: const ['u1'],
      createdAt: now,
      type: GroupType.friends,
      createdBy: 'u1',
      petId: 'gelada',
      petName: 'Desta',
    ),
    members: [CircleMember(profile: kaleab, status: null)],
  );

  final summaries = [
    CircleSummary(
      id: 'c1',
      name: 'Trail Crew',
      type: GroupType.friends,
      memberCount: 1,
      createdAt: now,
      petId: 'gelada',
      petName: 'Desta',
    ),
    CircleSummary(
      id: 'c2',
      name: 'Family Table',
      type: GroupType.family,
      memberCount: 3,
      createdAt: now,
      petId: 'lion',
      petName: 'Anbessa',
      hasDestination: true,
    ),
  ];

  Future<SharedPreferences> pumpHub(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
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
    // The stickers loop forever, so settle by fixed pumps.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return preferences;
  }

  bool isSelected(WidgetTester tester, String circleId) {
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(ValueKey('circle-card-$circleId')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    return semantics.properties.selected ?? false;
  }

  testWidgets('lists every circle and marks the active one', (tester) async {
    await pumpHub(tester);

    expect(find.byKey(const ValueKey('circle-card-c1')), findsOneWidget);
    expect(find.byKey(const ValueKey('circle-card-c2')), findsOneWidget);
    expect(find.text('Family Table'), findsOneWidget);
    expect(find.byKey(const ValueKey('circle-hub-add')), findsOneWidget);

    expect(isSelected(tester, 'c1'), isTrue);
    expect(isSelected(tester, 'c2'), isFalse);

    // The active pill uses the live mood; the rest read the summary.
    expect(find.byTooltip('Desta is resting'), findsOneWidget);
    expect(find.byTooltip('Anbessa is on the move'), findsOneWidget);
  });

  testWidgets('switching circles from the hub updates the active circle', (
    tester,
  ) async {
    final preferences = await pumpHub(tester);
    expect(ActiveCircleStore(preferences).read('u1'), isNull);

    await tester.tap(find.byKey(const ValueKey('circle-card-c2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(ActiveCircleStore(preferences).read('u1'), 'c2');
    expect(isSelected(tester, 'c2'), isTrue);
    expect(isSelected(tester, 'c1'), isFalse);
  });

  testWidgets('the hub add card opens the create or join sheet', (
    tester,
  ) async {
    await pumpHub(tester);

    await tester.tap(find.byKey(const ValueKey('circle-hub-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Add a circle'), findsOneWidget);
    expect(find.text('Create a Circle'), findsOneWidget);
    expect(find.text('Join a Circle'), findsOneWidget);
  });
}
