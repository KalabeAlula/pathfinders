import '../domain/circle.dart';
import '../domain/circle_snapshot.dart';
import '../domain/circle_summary.dart';
import '../domain/group_type.dart';

abstract interface class CircleRepository {
  /// Every group the signed-in user belongs to, oldest membership first.
  Stream<List<CircleSummary>> watchCircles();

  /// Live snapshot of one group, or `null` if the membership is gone.
  Stream<CircleSnapshot?> watchCircle(String circleId);

  Future<Circle> createCircle({
    required String name,
    required GroupType type,
    required String petId,
    required String petName,
  });

  Future<Circle> joinCircle({required String code});
}
