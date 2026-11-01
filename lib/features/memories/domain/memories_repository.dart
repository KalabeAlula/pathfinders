import 'memory_post.dart';

abstract interface class MemoriesRepository {
  Stream<List<MemoryPost>> watchMemories();

  Future<void> addMemory({
    required String authorId,
    required String text,
    required MemoryMood mood,
    String? placeLabel,
    int? voiceNoteSeconds,
  });
}
