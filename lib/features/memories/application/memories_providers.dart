import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/supabase_memories_repository.dart';
import '../domain/memories_repository.dart';
import '../domain/memory_post.dart';

part 'memories_providers.g.dart';

@Riverpod(keepAlive: true)
MemoriesRepository memoriesRepository(Ref ref, String circleId) =>
    SupabaseMemoriesRepository(
      ref.watch(supabaseClientProvider),
      circleId: circleId,
    );

@riverpod
Stream<List<MemoryPost>> recentMemories(Ref ref, String circleId) =>
    ref.watch(memoriesRepositoryProvider(circleId)).watchMemories();
