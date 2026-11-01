import '../domain/milestones_repository.dart';
import '../domain/shared_milestone.dart';

class MockMilestonesRepository implements MilestonesRepository {
  MockMilestonesRepository() : _milestones = _seed();

  final List<SharedMilestone> _milestones;

  @override
  Stream<List<SharedMilestone>> watchMilestones() => Stream.value(_milestones);

  static List<SharedMilestone> _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      SharedMilestone(
        id: 'milestone_hana_birthday',
        title: "Hana's birthday",
        subtitle: 'Plan the surprise dinner',
        date: today.add(const Duration(days: 12)),
        kind: MilestoneKind.birthday,
      ),
      SharedMilestone(
        id: 'milestone_hawassa',
        title: 'Hawassa weekend',
        subtitle: 'Three nights by the lake',
        date: today.add(const Duration(days: 34)),
        kind: MilestoneKind.trip,
      ),
      SharedMilestone(
        id: 'milestone_anniversary',
        title: 'One year of Bole Crew',
        subtitle: 'Cake, obviously',
        date: today.add(const Duration(days: 87)),
        kind: MilestoneKind.anniversary,
      ),
    ];
  }
}
