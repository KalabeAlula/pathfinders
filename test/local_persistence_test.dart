import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/chat/data/chat_seen_store.dart';
import 'package:pathfinders/features/memories/data/memories_cache.dart';
import 'package:pathfinders/features/memories/domain/memory_post.dart';
import 'package:pathfinders/features/milestones/data/milestones_cache.dart';
import 'package:pathfinders/features/milestones/domain/shared_milestone.dart';
import 'package:pathfinders/features/navigation/data/arrival_store.dart';
import 'package:pathfinders/features/navigation/data/search_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

MemoryPost _memory(
  String id, {
  MemoryMood mood = MemoryMood.cozy,
  String? photoPath,
}) {
  return MemoryPost(
    id: id,
    authorId: 'alex',
    text: 'A slow evening on Entoto',
    mood: mood,
    createdAt: DateTime(2026, 10, 31, 18, 30),
    placeLabel: 'Entoto Park',
    voiceNoteSeconds: 12,
    photoPath: photoPath,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MemoriesCache', () {
    test('returns null before anything has been cached', () async {
      final preferences = await SharedPreferences.getInstance();
      final cache = MemoriesCache(preferences, circleId: 'c1');

      expect(cache.read(), isNull);
    });

    test('round-trips every field and stays per circle', () async {
      final preferences = await SharedPreferences.getInstance();
      final cache = MemoriesCache(preferences, circleId: 'c1');
      final memories = [
        _memory('m1', mood: MemoryMood.joyful, photoPath: 'c1/alex/m1.jpg'),
        _memory('m2', mood: MemoryMood.proud),
      ];

      await cache.write(memories);
      final restored = cache.read()!;

      expect(restored, hasLength(2));
      expect(restored.first.id, 'm1');
      expect(restored.first.mood, MemoryMood.joyful);
      expect(restored.first.createdAt, memories.first.createdAt);
      expect(restored.first.placeLabel, 'Entoto Park');
      expect(restored.first.voiceNoteSeconds, 12);
      expect(restored.first.photoPath, 'c1/alex/m1.jpg');
      expect(restored.last.photoPath, isNull);
      expect(MemoriesCache(preferences, circleId: 'c2').read(), isNull);
    });

    test('keeps only the newest forty entries', () async {
      final preferences = await SharedPreferences.getInstance();
      final cache = MemoriesCache(preferences, circleId: 'c1');

      await cache.write([for (var i = 0; i < 45; i++) _memory('m$i')]);
      final restored = cache.read()!;

      expect(restored, hasLength(MemoriesCache.maxEntries));
      expect(restored.first.id, 'm0');
      expect(restored.last.id, 'm39');
    });

    test('ignores a corrupt payload instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'memories.cache.c1': '{not json',
      });
      final preferences = await SharedPreferences.getInstance();

      expect(MemoriesCache(preferences, circleId: 'c1').read(), isNull);
    });

    test('skips a corrupt entry but keeps its neighbours', () async {
      SharedPreferences.setMockInitialValues({
        'memories.cache.c1': jsonEncode([
          {
            'id': 'm1',
            'authorId': 'alex',
            'text': 'Still here',
            'mood': 'calm',
            'createdAt': '2026-10-31T18:30:00.000Z',
          },
          {'id': 7},
        ]),
      });
      final preferences = await SharedPreferences.getInstance();

      final restored = MemoriesCache(preferences, circleId: 'c1').read();

      expect(restored, hasLength(1));
      expect(restored!.single.id, 'm1');
    });
  });

  group('MilestonesCache', () {
    test('round-trips the countdown list per circle', () async {
      final preferences = await SharedPreferences.getInstance();
      final cache = MilestonesCache(preferences, circleId: 'c1');
      final milestones = [
        SharedMilestone(
          id: 's1',
          title: 'Anniversary',
          date: DateTime(2026, 12, 24),
          kind: MilestoneKind.anniversary,
          subtitle: 'Dinner at the usual spot',
        ),
        SharedMilestone(
          id: 's2',
          title: 'Lalibela trip',
          date: DateTime(2027, 1, 5),
          kind: MilestoneKind.trip,
        ),
      ];

      await cache.write(milestones);
      final restored = cache.read()!;

      expect(restored, hasLength(2));
      expect(restored.first.title, 'Anniversary');
      expect(restored.first.date, DateTime(2026, 12, 24));
      expect(restored.first.kind, MilestoneKind.anniversary);
      expect(restored.first.subtitle, 'Dinner at the usual spot');
      expect(restored.last.subtitle, isNull);
      expect(MilestonesCache(preferences, circleId: 'c2').read(), isNull);
    });

    test('ignores a corrupt payload instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'milestones.cache.c1': '[] trailing',
      });
      final preferences = await SharedPreferences.getInstance();

      expect(MilestonesCache(preferences, circleId: 'c1').read(), isNull);
    });
  });

  group('ChatSeenStore', () {
    test('returns null for a thread that has never been opened', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = ChatSeenStore(preferences);

      expect(store.read('c1'), isNull);
    });

    test('restores the same moment after a restart', () async {
      final preferences = await SharedPreferences.getInstance();
      final seenAt = DateTime(2026, 11, 2, 9, 30);
      final store = ChatSeenStore(preferences);

      await store.write('c1', seenAt);
      final restored = ChatSeenStore(preferences).read('c1');

      expect(restored, isNotNull);
      expect(restored!.isAtSameMomentAs(seenAt), isTrue);
    });

    test('keeps one timestamp per circle', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = ChatSeenStore(preferences);

      await store.write('c1', DateTime(2026, 11, 2, 9));
      await store.write('c2', DateTime(2026, 11, 2, 10));

      expect(store.read('c1'), DateTime(2026, 11, 2, 9));
      expect(store.read('c2'), DateTime(2026, 11, 2, 10));
    });
  });

  group('ArrivalStore', () {
    test('returns null until an arrival has been announced', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = ArrivalStore(preferences);

      expect(store.read('c1'), isNull);
    });

    test('round-trips one trip key per circle', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = ArrivalStore(preferences);

      await store.write('c1', 'trip-a');
      await store.write('c2', 'trip-b');

      expect(ArrivalStore(preferences).read('c1'), 'trip-a');
      expect(store.read('c2'), 'trip-b');
    });

    test('clears an announced trip', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = ArrivalStore(preferences);

      await store.write('c1', 'trip-a');
      await store.clear('c1');

      expect(store.read('c1'), isNull);
    });
  });

  group('SearchHistoryStore', () {
    test('starts empty and records newest first', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SearchHistoryStore(preferences, userId: 'u1');

      expect(store.read(), isEmpty);

      await store.remember('Blue Nile');
      await store.remember('Pizza');

      expect(store.read(), ['Pizza', 'Blue Nile']);
    });

    test('moves a repeated query to the front and ignores case', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SearchHistoryStore(preferences, userId: 'u1');

      await store.remember('Blue Nile');
      await store.remember('Pizza');
      await store.remember('  blue nile ');

      expect(store.read(), ['blue nile', 'Pizza']);
    });

    test('keeps only the five most recent queries', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SearchHistoryStore(preferences, userId: 'u1');

      for (final query in ['a', 'b', 'c', 'd', 'e', 'f', 'g']) {
        await store.remember(query);
      }

      expect(store.read(), ['g', 'f', 'e', 'd', 'c']);
    });

    test('keeps history separate per member', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SearchHistoryStore(preferences, userId: 'u1');

      await store.remember('Entoto');

      expect(SearchHistoryStore(preferences, userId: 'u2').read(), isEmpty);
    });

    test('ignores blank queries', () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SearchHistoryStore(preferences, userId: 'u1');

      await store.remember('   ');

      expect(store.read(), isEmpty);
    });
  });
}
