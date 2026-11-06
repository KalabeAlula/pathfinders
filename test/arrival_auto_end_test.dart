import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:pathfinders/features/auth/application/auth_providers.dart';
import 'package:pathfinders/features/auth/domain/auth_session.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/location/application/telemetry_providers.dart';
import 'package:pathfinders/features/location/domain/device_telemetry.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/location/domain/member_status.dart';
import 'package:pathfinders/features/location/domain/privacy_mode.dart';
import 'package:pathfinders/features/navigation/application/arrival_controller.dart';
import 'package:pathfinders/features/navigation/application/navigation_providers.dart';
import 'package:pathfinders/features/navigation/domain/arrival.dart';
import 'package:pathfinders/features/navigation/domain/navigation_destination.dart'
    as nav;
import 'package:pathfinders/features/navigation/domain/navigation_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepository implements NavigationRepository {
  int clears = 0;

  @override
  Future<void> clearDestination() async => clears++;

  @override
  Future<void> setDestination({
    required String label,
    required double latitude,
    required double longitude,
    required String setBy,
  }) async {}

  @override
  Stream<nav.NavigationDestination?> watchDestination() => const Stream.empty();
}

void main() {
  final now = DateTime(2026, 11, 6, 15);
  const target = GeoPoint(latitude: 9.0, longitude: 38.75);
  const farAway = GeoPoint(latitude: 9.02, longitude: 38.77);

  final destination = nav.NavigationDestination(
    latitude: target.latitude,
    longitude: target.longitude,
    label: 'Century Mall',
    setBy: 'u1',
    updatedAt: now,
  );

  CircleSnapshot snapshotWith({GeoPoint? peerPoint, bool peerOnline = true}) {
    return CircleSnapshot(
      circle: Circle(
        id: 'c1',
        name: 'Trail Crew',
        inviteCode: 'PF-9K2Q',
        memberIds: const ['u1', 'u2'],
        createdAt: now,
        petId: 'gelada',
        petName: 'Desta',
      ),
      members: [
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
            location: peerPoint,
            batteryPercent: 70,
            isCharging: false,
            speedKph: 0,
            isOnline: peerOnline,
            privacyMode: PrivacyMode.exact,
            updatedAt: now,
          ),
        ),
      ],
    );
  }

  ProviderContainer containerFor({
    required CircleSnapshot snapshot,
    required _FakeRepository repository,
    required SharedPreferences preferences,
  }) {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authSessionProvider.overrideWith(
          (ref) => Stream.value(
            const AuthSession(userId: 'u1', email: 'kaleab@example.com'),
          ),
        ),
        circleDestinationProvider('c1')
            .overrideWith((ref) => Stream.value(destination)),
        circleSnapshotProvider('u1')
            .overrideWith((ref) => Stream.value(snapshot)),
        telemetryControllerProvider('u1').overrideWithValue(
          const TelemetryState(
            ready: true,
            permission: TelemetryPermission.granted,
            lastReading: DeviceReading(
              point: target,
              accuracyMeters: 5,
              speedKph: 0,
            ),
          ),
        ),
        navigationRepositoryProvider('c1').overrideWithValue(repository),
      ],
    );
  }

  Future<SharedPreferences> preferencesWithAnnouncement() async {
    SharedPreferences.setMockInitialValues({
      'navigation.arrived.c1': destinationTripKey(destination),
    });
    return SharedPreferences.getInstance();
  }

  /// Riverpod schedules rebuilds on a zero-time tick, so the stubbed streams
  /// need one before the controller sees a complete state.
  void settle(FakeAsync async) {
    async.flushMicrotasks();
    async.elapse(const Duration(milliseconds: 1));
    async.flushMicrotasks();
  }

  test('clears the shared destination once everyone has arrived', () async {
    final preferences = await preferencesWithAnnouncement();
    final repository = _FakeRepository();

    fakeAsync((async) {
      final container = containerFor(
        snapshot: snapshotWith(peerPoint: target),
        repository: repository,
        preferences: preferences,
      );
      addTearDown(container.dispose);
      container.listen(arrivalControllerProvider('c1'), (_, _) {});
      settle(async);

      expect(
        container.read(arrivalControllerProvider('c1')).everyoneArrived,
        isTrue,
      );
      expect(repository.clears, 0);

      async.elapse(arrivalAutoEndGrace - const Duration(seconds: 1));
      expect(repository.clears, 0);

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(repository.clears, 1);
    });
  });

  test('keeps the trip alive while a member is still en route', () async {
    final preferences = await preferencesWithAnnouncement();
    final repository = _FakeRepository();

    fakeAsync((async) {
      final container = containerFor(
        snapshot: snapshotWith(peerPoint: farAway),
        repository: repository,
        preferences: preferences,
      );
      addTearDown(container.dispose);
      container.listen(arrivalControllerProvider('c1'), (_, _) {});
      settle(async);

      expect(
        container.read(arrivalControllerProvider('c1')).everyoneArrived,
        isFalse,
      );

      async.elapse(arrivalAutoEndGrace * 4);
      async.flushMicrotasks();
      expect(repository.clears, 0);
    });
  });

  test('keeps the trip alive when a member has gone dark', () async {
    final preferences = await preferencesWithAnnouncement();
    final repository = _FakeRepository();

    fakeAsync((async) {
      final container = containerFor(
        snapshot: snapshotWith(peerPoint: target, peerOnline: false),
        repository: repository,
        preferences: preferences,
      );
      addTearDown(container.dispose);
      container.listen(arrivalControllerProvider('c1'), (_, _) {});
      settle(async);

      expect(
        container.read(arrivalControllerProvider('c1')).everyoneArrived,
        isFalse,
      );

      async.elapse(arrivalAutoEndGrace * 4);
      async.flushMicrotasks();
      expect(repository.clears, 0);
    });
  });
}
