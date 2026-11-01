import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/supabase_milestones_repository.dart';
import '../domain/milestones_repository.dart';
import '../domain/shared_milestone.dart';

part 'milestones_providers.g.dart';

@Riverpod(keepAlive: true)
MilestonesRepository milestonesRepository(Ref ref, String circleId) =>
    SupabaseMilestonesRepository(
      ref.watch(supabaseClientProvider),
      circleId: circleId,
    );

@riverpod
Stream<List<SharedMilestone>> milestones(Ref ref, String circleId) =>
    ref.watch(milestonesRepositoryProvider(circleId)).watchMilestones();
