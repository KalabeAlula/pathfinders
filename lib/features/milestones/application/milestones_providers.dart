import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/milestones_cache.dart';
import '../data/supabase_milestones_repository.dart';
import '../domain/milestones_repository.dart';
import '../domain/shared_milestone.dart';

part 'milestones_providers.g.dart';

@riverpod
MilestonesCache milestonesCache(Ref ref, String circleId) =>
    MilestonesCache(ref.watch(sharedPreferencesProvider), circleId: circleId);

@Riverpod(keepAlive: true)
MilestonesRepository milestonesRepository(Ref ref, String circleId) =>
    SupabaseMilestonesRepository(
      ref.watch(supabaseClientProvider),
      circleId: circleId,
      cache: ref.watch(milestonesCacheProvider(circleId)),
    );

@riverpod
Stream<List<SharedMilestone>> milestones(Ref ref, String circleId) =>
    ref.watch(milestonesRepositoryProvider(circleId)).watchMilestones();
