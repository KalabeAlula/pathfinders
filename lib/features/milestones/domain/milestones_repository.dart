import 'shared_milestone.dart';

abstract interface class MilestonesRepository {
  Stream<List<SharedMilestone>> watchMilestones();

  Future<void> addMilestone({
    required String createdBy,
    required String title,
    required DateTime date,
    required MilestoneKind kind,
    String? subtitle,
  });
}
