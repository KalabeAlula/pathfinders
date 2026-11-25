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
    int onlineCount = 0,
    bool countdownSoon = false,
    int recentChatCount = 0,
    bool recentMemory = false,
  }) {
    return derivePetMood(
      hasDestination: hasDestination,
      arrived: arrived,
      everyoneArrived: everyoneArrived,
      now: now ?? daytime,
      energy: energy,
      lastActivityAt: lastActivityAt,
      onlineCount: onlineCount,
      countdownSoon: countdownSoon,
      recentChatCount: recentChatCount,
      recentMemory: recentMemory,
    );
  }

  test('a calm daytime circle is idle', () {
    expect(mood(lastActivityAt: daytime), PetMood.idle);
  });

  test('a destination sends the companion traveling', () {
    expect(mood(hasDestination: true), PetMood.traveling);
  });

  test('an arrival celebrates instead of traveling', () {
    expect(mood(hasDestination: true, arrived: true), PetMood.celebrating);
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

  group('contextual moods', () {
    test('hyped when 2+ members online and countdown within 48h', () {
      expect(mood(onlineCount: 2, countdownSoon: true), PetMood.hyped);
      expect(mood(onlineCount: 3, countdownSoon: true), PetMood.hyped);
    });

    test('hyped when 2+ members online and 3+ recent chat messages', () {
      expect(mood(onlineCount: 2, recentChatCount: 3), PetMood.hyped);
      expect(mood(onlineCount: 3, recentChatCount: 5), PetMood.hyped);
    });

    test('not hyped with only 1 member online', () {
      expect(mood(onlineCount: 1, countdownSoon: true), PetMood.idle);
    });

    test('curious when recent memory posted', () {
      expect(mood(recentMemory: true), PetMood.curious);
    });

    test('curious when 5+ recent chat messages', () {
      expect(mood(recentChatCount: 5), PetMood.curious);
      expect(mood(recentChatCount: 10), PetMood.curious);
    });

    test('hungry when energy drops below threshold', () {
      expect(mood(energy: 30), PetMood.hungry);
      expect(mood(energy: 20), PetMood.hungry);
    });

    test('hungry does not override sleeping at night', () {
      expect(
        mood(energy: 30, now: DateTime(2026, 11, 5, 23)),
        PetMood.sleeping,
      );
    });

    test('hungry does not show when rested for 8+ hours', () {
      expect(
        mood(
          energy: 30,
          lastActivityAt: daytime.subtract(const Duration(hours: 9)),
        ),
        PetMood.sleeping,
      );
    });
  });

  group('mood priority order', () {
    test('trip moods beat contextual moods', () {
      expect(
        mood(hasDestination: true, onlineCount: 3, countdownSoon: true),
        PetMood.traveling,
      );
      expect(
        mood(hasDestination: true, arrived: true, recentMemory: true),
        PetMood.celebrating,
      );
    });

    test('hyped beats curious', () {
      expect(
        mood(onlineCount: 2, countdownSoon: true, recentMemory: true),
        PetMood.hyped,
      );
    });

    test('curious beats hungry', () {
      expect(mood(recentMemory: true, energy: 30), PetMood.curious);
    });

    test('hungry beats sleeping when awake', () {
      expect(mood(energy: 30, lastActivityAt: daytime), PetMood.hungry);
    });
  });
}
