import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/memories_cache.dart';
import '../data/memories_seen_store.dart';
import '../data/memory_photo_urls.dart';
import '../data/supabase_memories_repository.dart';
import '../domain/memories_repository.dart';
import '../domain/memory_post.dart';

part 'memories_providers.g.dart';

@riverpod
MemoriesCache memoriesCache(Ref ref, String circleId) =>
    MemoriesCache(ref.watch(sharedPreferencesProvider), circleId: circleId);

@riverpod
MemoriesSeenStore memoriesSeenStore(Ref ref) =>
    MemoriesSeenStore(ref.watch(sharedPreferencesProvider));

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

/// The moment this device last opened the circle's memories gallery, restored
/// after restarts so the dock badge only counts moments not yet seen.
@Riverpod(keepAlive: true)
class MemoriesSeenController extends _$MemoriesSeenController {
  @override
  DateTime build(String circleId) =>
      ref.watch(memoriesSeenStoreProvider).read(circleId) ?? DateTime.now();

  void markSeen() {
    final seenAt = DateTime.now();
    state = seenAt;
    unawaited(ref.read(memoriesSeenStoreProvider).write(circleId, seenAt));
  }
}

typedef MemoriesUnreadQuery = ({String circleId, String userId});

@riverpod
int memoriesUnreadCount(Ref ref, MemoriesUnreadQuery query) {
  final lastSeen = ref.watch(memoriesSeenControllerProvider(query.circleId));
  final memories =
      ref.watch(recentMemoriesProvider(query.circleId)).value ??
      const <MemoryPost>[];

  return memories
      .where(
        (memory) =>
            memory.authorId != query.userId &&
            memory.createdAt.isAfter(lastSeen),
      )
      .length;
}
