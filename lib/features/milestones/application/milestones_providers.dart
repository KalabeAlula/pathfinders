import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mock_milestones_repository.dart';
import '../domain/milestones_repository.dart';
import '../domain/shared_milestone.dart';

part 'milestones_providers.g.dart';

@Riverpod(keepAlive: true)
MilestonesRepository milestonesRepository(Ref ref) =>
    MockMilestonesRepository();

@riverpod
Stream<SharedMilestone?> nextMilestone(Ref ref) {
  return ref
      .watch(milestonesRepositoryProvider)
      .watchMilestones()
      .map((milestones) => milestones.isEmpty ? null : milestones.first);
}
