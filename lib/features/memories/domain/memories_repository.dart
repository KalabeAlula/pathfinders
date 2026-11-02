import 'memory_photo.dart';
import 'memory_post.dart';

abstract interface class MemoriesRepository {
  Stream<List<MemoryPost>> watchMemories();

  /// Saves a memory. [text] may be empty when [photo] is provided.
  Future<void> addMemory({
    required String authorId,
    required String text,
    required MemoryMood mood,
    String? placeLabel,
    int? voiceNoteSeconds,
    MemoryPhotoDraft? photo,
  });

  /// Deletes one of the caller's memories and, when given, its photo object.
  Future<void> deleteMemory(String memoryId, {String? photoPath});

  /// Leaves [emoji] on a memory, replacing the caller's previous reaction.
  Future<void> setReaction({required String memoryId, required String emoji});

  /// Removes the caller's reaction to a memory.
  Future<void> clearReaction(String memoryId);
}
