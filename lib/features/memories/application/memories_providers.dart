import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mock_memories_repository.dart';
import '../domain/memories_repository.dart';
import '../domain/memory_post.dart';

part 'memories_providers.g.dart';

@Riverpod(keepAlive: true)
MemoriesRepository memoriesRepository(Ref ref) => MockMemoriesRepository();

@riverpod
Stream<List<MemoryPost>> recentMemories(Ref ref) =>
    ref.watch(memoriesRepositoryProvider).watchMemories();
