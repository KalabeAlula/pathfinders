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

  /// Removes the caller from the circle. The creator must delete instead.
  Future<void> leaveCircle({required String circleId});

  /// Permanently removes the circle and everything it owns. Creator only.
  Future<void> deleteCircle({required String circleId});

  /// Renames the circle. Creator only.
  Future<void> renameCircle({required String circleId, required String name});

  /// Issues a fresh invite code and returns it. Creator only.
  Future<String> rotateInviteCode({required String circleId});

  /// Removes another member from the circle. Creator only.
  Future<void> removeMember({
    required String circleId,
    required String memberId,
  });

  /// Hands circle ownership to another member. Creator only.
  Future<void> transferOwnership({
    required String circleId,
    required String newOwnerId,
  });
}
