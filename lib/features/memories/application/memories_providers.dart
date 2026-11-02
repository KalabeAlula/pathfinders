import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/memories_cache.dart';
import '../data/memory_photo_urls.dart';
import '../data/supabase_memories_repository.dart';
import '../domain/memories_repository.dart';
import '../domain/memory_post.dart';

part 'memories_providers.g.dart';

@riverpod
MemoriesCache memoriesCache(Ref ref, String circleId) =>
    MemoriesCache(ref.watch(sharedPreferencesProvider), circleId: circleId);

@Riverpod(keepAlive: true)
MemoryPhotoUrls memoryPhotoUrls(Ref ref) =>
    MemoryPhotoUrls(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
MemoriesRepository memoriesRepository(Ref ref, String circleId) =>
    SupabaseMemoriesRepository(
      ref.watch(supabaseClientProvider),
      circleId: circleId,
      cache: ref.watch(memoriesCacheProvider(circleId)),
    );

@riverpod
Stream<List<MemoryPost>> recentMemories(Ref ref, String circleId) =>
    ref.watch(memoriesRepositoryProvider(circleId)).watchMemories();
