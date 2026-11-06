import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
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
import '../domain/navigation_failure.dart';
import '../domain/route_geometry.dart';
import 'navigation_providers.dart';
import 'trip_auto_end.dart';

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

/// Detects the local member's arrival at the shared destination, announces it
/// in the crew thread once per trip, and ends the trip once everyone is there.
@Riverpod(keepAlive: true)
class ArrivalController extends _$ArrivalController {
  bool _announcing = false;
  String? _circleId;
  late final TripAutoEnd _autoEnd = TripAutoEnd(onFinish: _finishTrip);

  @override
  ArrivalState build(String circleId) {
    _circleId = circleId;
    final userId = ref.watch(authSessionProvider).value?.userId;
    final destination = ref.watch(circleDestinationProvider(circleId)).value;
    if (userId == null || destination == null) {
      _autoEnd.cancel();
      return const ArrivalState();
    }

    final snapshot = ref.watch(circleSnapshotProvider(userId)).value;
    final reading = ref.watch(
      telemetryControllerProvider(userId).select((state) => state.lastReading),
    );
    final localPoint = reading?.point;
    final arrived =
        localPoint != null &&
        isWithinArrivalRadius(
          localPoint,
          destination.point,
          accuracyMeters: reading?.accuracyMeters ?? 0,
        );
    final everyoneArrived = _everyoneArrived(
      userId: userId,
      snapshot: snapshot,
      destination: destination,
      localPoint: localPoint,
    );

    if (arrived) {
      unawaited(_announce(circleId, userId, destination, snapshot));
    }
    _autoEnd.update(
      tripKey: destinationTripKey(destination),
      everyoneArrived: everyoneArrived,
    );

    return ArrivalState(
      destination: destination,
      distanceMeters: localPoint == null
          ? null
          : distanceMeters(localPoint, destination.point),
      arrived: arrived,
      everyoneArrived: everyoneArrived,
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

  /// Clears the shared destination for the whole circle.
  ///
  /// Re-reads the destination first: a member may have set a new trip while
  /// the timer was counting down, and that trip must not be cancelled.
  Future<bool> _finishTrip(String tripKey) async {
    if (!ref.mounted) return false;
    final circleId = _circleId;
    if (circleId == null) return false;

    final current = ref.read(circleDestinationProvider(circleId)).value;
    if (current == null) return true;
    if (destinationTripKey(current) != tripKey) return true;

    try {
      await ref.read(navigationRepositoryProvider(circleId)).clearDestination();
      return true;
    } on NavigationFailure catch (failure) {
      developer.log(
        'Could not auto-end the trip: ${failure.message}',
        name: 'pathfinders.arrival',
        error: failure,
      );
      return false;
    } on Exception catch (error) {
      developer.log(
        'Could not auto-end the trip',
        name: 'pathfinders.arrival',
        error: error,
      );
      return false;
    }
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
