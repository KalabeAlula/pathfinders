import 'shared_milestone.dart';

abstract interface class MilestonesRepository {
  Stream<List<SharedMilestone>> watchMilestones();
}
