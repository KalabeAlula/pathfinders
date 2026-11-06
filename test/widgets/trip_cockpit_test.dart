import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/core/application/clock_provider.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/location/application/telemetry_providers.dart';
import 'package:pathfinders/features/location/domain/device_telemetry.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/location/domain/member_status.dart';
import 'package:pathfinders/features/location/domain/privacy_mode.dart';
import 'package:pathfinders/features/navigation/application/navigation_providers.dart';
import 'package:pathfinders/features/navigation/application/navigation_state.dart';
import 'package:pathfinders/features/navigation/domain/navigation_destination.dart'
    as nav;
import 'package:pathfinders/features/navigation/domain/navigation_maneuver.dart';
import 'package:pathfinders/features/navigation/domain/navigation_repository.dart';
import 'package:pathfinders/features/navigation/domain/route_plan.dart';
import 'package:pathfinders/features/navigation/domain/route_progress.dart';
import 'package:pathfinders/features/navigation/domain/route_step.dart';
import 'package:pathfinders/features/navigation/presentation/widgets/maneuver_banner.dart';
import 'package:pathfinders/features/navigation/presentation/widgets/trip_cockpit.dart';
import 'package:pathfinders/features/navigation/presentation/widgets/trip_summary_bar.dart';

class _FakeRepository implements NavigationRepository {
  bool cleared = false;

  @override
  Future<void> clearDestination() async => cleared = true;

  @override
  Future<void> setDestination({
    required String label,
    required double latitude,
    required double longitude,
    required String setBy,
  }) async {}

  @override
  Stream<nav.NavigationDestination?> watchDestination() =>
      const Stream.empty();
}

void main() {
  final now = DateTime(2026, 11, 6, 14);
  const start = GeoPoint(latitude: 0, longitude: 0);
  const turn = GeoPoint(latitude: 0, longitude: 0.01);
  const finish = GeoPoint(latitude: 0, longitude: 0.02);

  RouteStep step(ManeuverKind kind, GeoPoint at, String road) => RouteStep(
    kind: kind,
    roadName: road,
    distanceMeters: 0,
    duration: Duration.zero,
    location: at,
  );

  final selfPlan = RoutePlan(
    geometry: const [start, turn, finish],
    distanceMeters: 2224,
    duration: const Duration(minutes: 20),
    steps: [
      step(ManeuverKind.depart, start, 'Bole Road'),
      step(ManeuverKind.turnLeft, turn, 'Africa Ave'),
      step(ManeuverKind.arrive, finish, 'Century Mall'),
    ],
    fetchedAt: now,
  );

  final peerPlan = RoutePlan(
    geometry: const [start, finish],
    distanceMeters: 2224,
    duration: const Duration(minutes: 6),
    fetchedAt: now,
  );

  final destination = nav.NavigationDestination(
    latitude: finish.latitude,
    longitude: finish.longitude,
    label: 'Century Mall',
    setBy: 'u1',
    updatedAt: now,
  );

  final navigation = NavigationState(
    destination: destination,
    routes: {
      'u1': MemberRoute(
        memberId: 'u1',
        plan: selfPlan,
        origin: start,
        computedAt: now,
      ),
      'u2': MemberRoute(
        memberId: 'u2',
        plan: peerPlan,
        origin: start,
        computedAt: now,
      ),
    },
    isConfigured: true,
  );

  final members = [
    const CircleMember(
      profile: UserProfile(
        id: 'u1',
        displayName: 'Kaleab Tesfaye',
        avatarColor: 0xFFB86B4F,
      ),
      status: null,
    ),
    CircleMember(
      profile: const UserProfile(
        id: 'u2',
        displayName: 'Alex Mekonnen',
        avatarColor: 0xFF7C8C6B,
      ),
      status: MemberStatus(
        userId: 'u2',
        location: start,
        batteryPercent: 80,
        isCharging: false,
        speedKph: 20,
        isOnline: true,
        privacyMode: PrivacyMode.exact,
        updatedAt: now,
      ),
    ),
  ];

  Widget cockpitHost(
    NavigationState state, {
    NavigationRepository? repository,
  }) {
    return ProviderScope(
      overrides: [
        navigationControllerProvider('c1').overrideWithValue(state),
        telemetryControllerProvider('u1').overrideWithValue(
          TelemetryState(
            ready: true,
            permission: TelemetryPermission.granted,
            lastReading: const DeviceReading(
              point: GeoPoint(latitude: 0, longitude: 0.004),
              accuracyMeters: 5,
              speedKph: 20,
            ),
          ),
        ),
        appClockProvider.overrideWith((_) => Stream.value(now)),
        if (repository != null)
          navigationRepositoryProvider('c1').overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TripCockpit(
            circleId: 'c1',
            currentUserId: 'u1',
            members: members,
          ),
        ),
      ),
    );
  }

  testWidgets('activates the cockpit once a destination is set', (tester) async {
    await tester.pumpWidget(cockpitHost(navigation));
    await tester.pump();

    expect(find.byType(ManeuverBanner), findsOneWidget);
    expect(find.byType(TripSummaryBar), findsOneWidget);
    expect(find.text('In 670 m'), findsOneWidget);
    expect(find.text('Africa Ave'), findsOneWidget);
    expect(find.text('Then arrive at Century Mall'), findsOneWidget);
    expect(find.text('To Century Mall'), findsOneWidget);
    expect(find.text('16 min'), findsOneWidget);
    expect(find.text('1.8 km • 2:16 PM'), findsOneWidget);
    expect(find.text('Alex: 6 min'), findsOneWidget);
  });

  testWidgets('stays out of the way without a destination', (tester) async {
    await tester.pumpWidget(
      cockpitHost(const NavigationState(isConfigured: true)),
    );
    await tester.pump();

    expect(find.byType(ManeuverBanner), findsNothing);
    expect(find.byType(TripSummaryBar), findsNothing);
  });

  testWidgets('end trip asks first, then clears the circle destination', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      cockpitHost(navigation, repository: repository),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('End navigation?'), findsOneWidget);
    expect(repository.cleared, isFalse);

    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(repository.cleared, isFalse);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End trip'));
    await tester.pumpAndSettle();

    expect(repository.cleared, isTrue);
    expect(find.text('Navigation ended.'), findsOneWidget);
  });

  group('ManeuverBanner', () {
    testWidgets('leads with the distance, road, and next move', (tester) async {
      final banner = ManeuverBanner(
        maneuver: NavigationManeuver(
          next: step(ManeuverKind.turnLeft, turn, 'Bole Road'),
          following: step(ManeuverKind.turnRight, finish, 'Africa Ave'),
          distanceMeters: 250,
        ),
        onChat: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: banner),
        ),
      );

      expect(find.text('In 250 m'), findsOneWidget);
      expect(find.text('Bole Road'), findsOneWidget);
      expect(find.text('Then turn right onto Africa Ave'), findsOneWidget);
      expect(find.byIcon(Icons.turn_left_rounded), findsOneWidget);
      expect(find.byTooltip('Open group chat'), findsOneWidget);
    });
  });

  group('TripSummaryBar', () {
    testWidgets('formats the ETA and peer chips', (tester) async {
      final bar = TripSummaryBar(
        destinationLabel: 'Century Mall',
        progress: RouteProgress(
          remainingMeters: 3800,
          remaining: const Duration(minutes: 14),
          arrival: DateTime(2026, 11, 6, 14, 15),
          arrived: false,
        ),
        peers: [
          PeerTrip(
            profile: const UserProfile(
              id: 'u2',
              displayName: 'Alex Mekonnen',
              avatarColor: 0xFF7C8C6B,
            ),
            progress: RouteProgress(
              remainingMeters: 1200,
              remaining: const Duration(minutes: 6),
              arrival: DateTime(2026, 11, 6, 14, 6),
              arrived: false,
            ),
          ),
          PeerTrip(
            profile: const UserProfile(
              id: 'u3',
              displayName: 'Sam Bekele',
              avatarColor: 0xFFC7974C,
            ),
            progress: RouteProgress(
              remainingMeters: 0,
              remaining: Duration.zero,
              arrival: DateTime(2026, 11, 6, 14),
              arrived: true,
            ),
          ),
        ],
        onEnd: () async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: bar),
        ),
      );

      expect(find.text('14 min'), findsOneWidget);
      expect(find.text('3.8 km • 2:15 PM'), findsOneWidget);
      expect(find.text('Alex: 6 min'), findsOneWidget);
      expect(find.text('Sam: Here'), findsOneWidget);
    });
  });
}
