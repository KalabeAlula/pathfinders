import 'dart:async';
import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../chat/application/chat_providers.dart';
import '../../circle/application/circle_providers.dart';
import '../../circle/domain/circle_member.dart';
import '../../circle/domain/circle_snapshot.dart';
import '../../location/application/telemetry_providers.dart';
import '../../location/domain/geo_point.dart';
import '../domain/arrival.dart';
import '../domain/navigation_destination.dart';
import '../domain/route_geometry.dart';
import 'navigation_providers.dart';

part 'arrival_controller.g.dart';

class ArrivalState {
  const ArrivalState({
    this.destination,
    this.distanceMeters,
    this.arrived = false,
    this.everyoneArrived = false,
  });

  final NavigationDestination? destination;
  final double? distanceMeters;
  final bool arrived;
  final bool everyoneArrived;

  String? get tripKey {
    final target = destination;
    return target == null ? null : destinationTripKey(target);
  }
}

/// Detects the local member's arrival at the shared destination and announces
/// it in the crew thread once per trip.
@Riverpod(keepAlive: true)
class ArrivalController extends _$ArrivalController {
  bool _announcing = false;

  @override
  ArrivalState build(String circleId) {
    final userId = ref.watch(authSessionProvider).value?.userId;
    final destination = ref.watch(circleDestinationProvider(circleId)).value;
    if (userId == null || destination == null) {
      return const ArrivalState();
    }

    final snapshot = ref.watch(circleSnapshotProvider(userId)).value;
    final reading = ref.watch(telemetryControllerProvider(userId)).lastReading;
    final localPoint = reading?.point;
    final arrived =
        localPoint != null &&
        isWithinArrivalRadius(
          localPoint,
          destination.point,
          accuracyMeters: reading?.accuracyMeters ?? 0,
        );

    if (arrived) {
      unawaited(_announce(circleId, userId, destination, snapshot));
    }

    return ArrivalState(
      destination: destination,
      distanceMeters: localPoint == null
          ? null
          : distanceMeters(localPoint, destination.point),
      arrived: arrived,
      everyoneArrived: _everyoneArrived(
        userId: userId,
        snapshot: snapshot,
        destination: destination,
        localPoint: localPoint,
      ),
    );
  }

  bool _everyoneArrived({
    required String userId,
    required CircleSnapshot? snapshot,
    required NavigationDestination destination,
    required GeoPoint? localPoint,
  }) {
    final members = snapshot?.members ?? const <CircleMember>[];
    if (members.isEmpty) return false;

    final points = <GeoPoint?>[
      for (final member in members)
        member.profile.id == userId ? localPoint : _sharedPoint(member),
    ];
    return allMembersWithinArrivalRadius(points, destination.point);
  }

  static GeoPoint? _sharedPoint(CircleMember member) {
    final status = member.status;
    if (status == null || !status.isOnline) return null;
    return status.location;
  }

  Future<void> _announce(
    String circleId,
    String userId,
    NavigationDestination destination,
    CircleSnapshot? snapshot,
  ) async {
    if (_announcing) return;

    final store = ref.read(arrivalStoreProvider);
    final tripKey = destinationTripKey(destination);
    if (store.read(circleId) == tripKey) return;

    // Wait for the profile so the announcement can name the member.
    final member = snapshot?.memberById(userId);
    if (member == null) return;

    _announcing = true;
    try {
      await ref
          .read(chatRepositoryProvider(circleId))
          .sendText(
            senderId: userId,
            text:
                '${member.profile.firstName} arrived at ${destination.label}!',
          );
      await store.write(circleId, tripKey);
    } on Exception catch (error) {
      developer.log(
        'Could not announce the arrival in chat',
        name: 'pathfinders.arrival',
        error: error,
      );
    } finally {
      _announcing = false;
    }
  }
}
