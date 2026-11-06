import 'shared_milestone.dart';

abstract interface class MilestonesRepository {
  Stream<List<SharedMilestone>> watchMilestones();

  Future<void> addMilestone({
    required String createdBy,
    required String title,
    required DateTime date,
    required MilestoneKind kind,
    String? subtitle,
    DateTime? startsAt,
    String? place,
  });

  /// Fills in, changes, or clears ([place] null) where the circle is meeting.
  Future<void> setPlace({required String milestoneId, required String? place});

  /// Fills in, changes, or clears ([startsAt] null) the start time.
  Future<void> setStartTime({
    required String milestoneId,
    required DateTime? startsAt,
  });

  /// Removes the countdown for everyone in the circle.
  Future<void> deleteMilestone(String milestoneId);
}
