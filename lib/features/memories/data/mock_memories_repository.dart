import '../../../core/mock/demo_ids.dart';
import '../domain/memories_repository.dart';
import '../domain/memory_post.dart';

class MockMemoriesRepository implements MemoriesRepository {
  MockMemoriesRepository() : _memories = _seed();

  final List<MemoryPost> _memories;

  @override
  Stream<List<MemoryPost>> watchMemories() => Stream.value(_memories);

  static List<MemoryPost> _seed() {
    final now = DateTime.now();
    return [
      MemoryPost(
        id: 'memory_tomoca',
        authorId: DemoIds.sofi,
        text: 'Found the tiniest coffee spot near Meskel. Saving you all a seat.',
        mood: MemoryMood.joyful,
        createdAt: now.subtract(const Duration(minutes: 38)),
        placeLabel: 'Tomoca Coffee',
        reactions: const {'🧡': 3, '☕': 2},
      ),
      MemoryPost(
        id: 'memory_momo',
        authorId: DemoIds.hana,
        text: 'Momo has officially claimed the sunny corner of the couch.',
        mood: MemoryMood.cozy,
        createdAt: now.subtract(const Duration(hours: 3)),
        voiceNoteSeconds: 6,
        reactions: const {'😄': 4, '🧡': 2},
      ),
      MemoryPost(
        id: 'memory_walk',
        authorId: DemoIds.kaleab,
        text: 'Day 4 of the walking challenge. The hills by Friendship Park are '
            'still undefeated.',
        mood: MemoryMood.proud,
        createdAt: now.subtract(const Duration(hours: 26)),
        placeLabel: 'Friendship Park',
        reactions: const {'💪': 3},
      ),
    ];
  }
}
