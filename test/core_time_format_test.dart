import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/utils/time_format.dart';

void main() {
  group('formatDwell', () {
    test('reads naturally for short stays', () {
      expect(formatDwell(const Duration(seconds: 20)), 'just arrived');
      expect(formatDwell(const Duration(minutes: 20)), '20m');
      expect(formatDwell(const Duration(minutes: 135)), '2h 15m');
      expect(formatDwell(const Duration(hours: 2)), '2h');
      expect(formatDwell(const Duration(days: 5, hours: 3)), '5d 3h');
    });
  });

  group('countdowns', () {
    test('formats the near future', () {
      expect(formatCountdown(0), 'Today');
      expect(formatCountdown(1), 'Tomorrow');
      expect(formatCountdown(12), 'In 12 days');
    });
  });

  group('timeAgo', () {
    final now = DateTime(2026, 11, 1, 18);

    test('handles fresh and older timestamps', () {
      expect(timeAgo(now, now: now), 'just now');
      expect(
        timeAgo(now.subtract(const Duration(minutes: 38)), now: now),
        '38m ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(hours: 3)), now: now),
        '3h ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(days: 2)), now: now),
        '2d ago',
      );
    });
  });

  test('greeting follows the time of day', () {
    expect(greetingFor(DateTime(2026, 11, 1, 7)), 'Good morning');
    expect(greetingFor(DateTime(2026, 11, 1, 14)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 11, 1, 20)), 'Good evening');
  });

  test('voice notes are rendered as minutes and seconds', () {
    expect(formatVoiceNote(6), '0:06');
    expect(formatVoiceNote(75), '1:15');
  });
}
