import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/clock_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../circle/application/circle_providers.dart';
import '../../navigation/application/arrival_controller.dart';
import '../domain/pet_mood.dart';

part 'pet_mood_providers.g.dart';

/// The companion's sticker state for [circleId].
///
/// Both watches are narrowed to the fields the mood needs: distance ticks and
/// member telemetry keep flowing without rebuilding every sticker.
@riverpod
PetMood petMood(Ref ref, String circleId) {
  final userId = ref.watch(authSessionProvider).value?.userId;
  if (userId == null) return PetMood.idle;

  final trip = ref.watch(
    arrivalControllerProvider(circleId).select(
      (state) => (
        hasDestination: state.destination != null,
        arrived: state.arrived,
        everyoneArrived: state.everyoneArrived,
      ),
    ),
  );

  final rest = ref.watch(
    circleSnapshotProvider(userId).select((snapshot) {
      final circle = snapshot.value?.circle;
      if (circle == null) return null;
      return (
        energy: circle.petEnergy,
        updatedAt: circle.petUpdatedAt ?? circle.createdAt,
      );
    }),
  );

  final now = ref.watch(appClockProvider).value ?? DateTime.now();
  return derivePetMood(
    hasDestination: trip.hasDestination,
    arrived: trip.arrived,
    everyoneArrived: trip.everyoneArrived,
    now: now,
    energy: rest?.energy ?? 100,
    lastActivityAt: rest?.updatedAt,
  );
}
