import 'circle_snapshot.dart';

abstract interface class CircleRepository {
  /// Emits `null` while the signed-in user has not joined a circle yet.
  Stream<CircleSnapshot?> watchCircle();

  Future<void> createCircle({required String name});

  Future<void> joinCircle({required String code});
}
