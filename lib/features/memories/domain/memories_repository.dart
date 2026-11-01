import 'memory_post.dart';

abstract interface class MemoriesRepository {
  Stream<List<MemoryPost>> watchMemories();
}
