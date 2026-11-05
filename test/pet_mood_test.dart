import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/pet/domain/pet_mood.dart';

void main() {
  final daytime = DateTime(2026, 11, 5, 18);

  PetMood mood({
    bool hasDestination = false,
    bool arrived = false,
    bool everyoneArrived = false,
    DateTime? now,
    double energy = 80,
    DateTime? lastActivityAt,
  }) {
    return derivePetMood(
      hasDestination: hasDestination,
      arrived: arrived,
      everyoneArrived: everyoneArrived,
      now: now ?? daytime,
      energy: energy,
      lastActivityAt: lastActivityAt,
    );
  }

  test('a calm daytime circle is idle', () {
    expect(mood(lastActivityAt: daytime), PetMood.idle);
  });

  test('a destination sends the companion traveling', () {
    expect(mood(hasDestination: true), PetMood.traveling);
  });

  test('an arrival celebrates instead of traveling', () {
    expect(
      mood(hasDestination: true, arrived: true),
      PetMood.celebrating,
    );
    expect(
      mood(hasDestination: true, everyoneArrived: true),
      PetMood.celebrating,
    );
  });

  test('the trip wins over bedtime', () {
    expect(
      mood(hasDestination: true, now: DateTime(2026, 11, 5, 23)),
      PetMood.traveling,
    );
  });

  test('late hours put the companion to sleep', () {
    expect(mood(now: DateTime(2026, 11, 5, 23)), PetMood.sleeping);
    expect(mood(now: DateTime(2026, 11, 5, 5)), PetMood.sleeping);
  });

  test('low energy or a long quiet stretch puts it to sleep', () {
    expect(mood(energy: 10), PetMood.sleeping);
    expect(
      mood(lastActivityAt: daytime.subtract(const Duration(hours: 9))),
      PetMood.sleeping,
    );
    expect(
      mood(lastActivityAt: daytime.subtract(const Duration(hours: 7))),
      PetMood.idle,
    );
  });

  test('idle becomes traveling then celebrating as the trip progresses', () {
    var current = mood();
    expect(current, PetMood.idle);

    current = mood(hasDestination: true);
    expect(current, PetMood.traveling);

    current = mood(hasDestination: true, arrived: true);
    expect(current, PetMood.celebrating);
  });
}
