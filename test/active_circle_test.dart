import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/data/active_circle_store.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_repository.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/circle/domain/circle_summary.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

CircleSummary _summary(
  String id, {
  GroupType type = GroupType.friends,
  int members = 1,
}) {
  return CircleSummary(
    id: id,
    name: 'Group $id',
    type: type,
    memberCount: members,
    createdAt: DateTime(2026, 1, 1),
  );
}

class _FakeCircleRepository implements CircleRepository {
  _FakeCircleRepository(this.summaries);

  final List<CircleSummary> summaries;
  final _summaryController = StreamController<List<CircleSummary>>.broadcast();
  final List<String> watched = [];
  final List<String> cancelled = [];
  final List<String> left = [];
  final List<String> deleted = [];

  @override
  Stream<List<CircleSummary>> watchCircles() {
    scheduleMicrotask(() {
      if (!_summaryController.isClosed) _summaryController.add(summaries);
    });
    return _summaryController.stream;
  }

  @override
  Stream<CircleSnapshot?> watchCircle(String circleId) {
    watched.add(circleId);
    late final StreamController<CircleSnapshot?> controller;
    controller = StreamController<CircleSnapshot?>(
      onCancel: () {
        cancelled.add(circleId);
        if (!controller.isClosed) controller.close();
      },
    );
    controller.add(
      CircleSnapshot(
        circle: Circle(
          id: circleId,
          name: 'Group $circleId',
          inviteCode: 'ABC234',
          memberIds: const ['u'],
          createdAt: DateTime(2026, 1, 1),
        ),
        members: const [],
      ),
    );
    return controller.stream;
  }

  @override
  Future<Circle> createCircle({
    required String name,
    required GroupType type,
    required String petId,
    required String petName,
  }) => throw UnimplementedError();

  @override
  Future<Circle> joinCircle({required String code}) =>
      throw UnimplementedError();

  @override
  Future<void> leaveCircle({required String circleId}) async {
    left.add(circleId);
    summaries.removeWhere((circle) => circle.id == circleId);
  }

  @override
  Future<void> deleteCircle({required String circleId}) async {
    deleted.add(circleId);
    summaries.removeWhere((circle) => circle.id == circleId);
  }

  @override
  Future<void> renameCircle({
    required String circleId,
    required String name,
  }) async {}

  @override
  Future<String> rotateInviteCode({required String circleId}) async => 'NEW234';

  @override
  Future<void> removeMember({
    required String circleId,
    required String memberId,
  }) async {}

  @override
  Future<void> transferOwnership({
    required String circleId,
    required String newOwnerId,
  }) async {}
}

Future<ProviderContainer> _start(_FakeCircleRepository repository) async {
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      circleRepositoryProvider('u').overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses the oldest group when nothing is saved', () async {
    final repository = _FakeCircleRepository([
      _summary('c1'),
      _summary('c2', type: GroupType.family, members: 5),
    ]);
    final container = await _start(repository);
    final circles = container.listen(circlesProvider('u'), (_, _) {});
    final snapshots = container.listen(circleSnapshotProvider('u'), (_, _) {});
    addTearDown(circles.close);
    addTearDown(snapshots.close);

    await container.read(circlesProvider('u').future);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeCircleControllerProvider('u')), 'c1');
    expect(container.read(activeCircleProvider('u'))?.id, 'c1');
    expect(repository.watched, ['c1']);
  });

  test('restores the saved group when it is still a membership', () async {
    SharedPreferences.setMockInitialValues({'active.circle.u': 'c2'});
    final repository = _FakeCircleRepository([_summary('c1'), _summary('c2')]);
    final container = await _start(repository);
    final circles = container.listen(circlesProvider('u'), (_, _) {});
    final snapshots = container.listen(circleSnapshotProvider('u'), (_, _) {});
    addTearDown(circles.close);
    addTearDown(snapshots.close);

    await container.read(circlesProvider('u').future);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeCircleControllerProvider('u')), 'c2');
    expect(repository.watched, ['c2']);
  });

  test('ignores a saved group that is no longer a membership', () async {
    SharedPreferences.setMockInitialValues({'active.circle.u': 'gone'});
    final repository = _FakeCircleRepository([_summary('c1')]);
    final container = await _start(repository);
    final circles = container.listen(circlesProvider('u'), (_, _) {});
    addTearDown(circles.close);

    await container.read(circlesProvider('u').future);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeCircleControllerProvider('u')), 'c1');
  });

  test(
    'selecting a group persists it and tears down the old snapshot',
    () async {
      final repository = _FakeCircleRepository([
        _summary('c1'),
        _summary('c2'),
      ]);
      final container = await _start(repository);
      final circles = container.listen(circlesProvider('u'), (_, _) {});
      final snapshots = container.listen(
        circleSnapshotProvider('u'),
        (_, _) {},
      );
      addTearDown(circles.close);
      addTearDown(snapshots.close);

      await container.read(circlesProvider('u').future);
      await Future<void>.delayed(Duration.zero);
      expect(repository.watched, ['c1']);

      final preferences = await SharedPreferences.getInstance();
      await container
          .read(activeCircleControllerProvider('u').notifier)
          .select('c2');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(activeCircleControllerProvider('u')), 'c2');
      expect(container.read(activeCircleProvider('u'))?.id, 'c2');
      expect(ActiveCircleStore(preferences).read('u'), 'c2');
      expect(repository.watched, ['c1', 'c2']);
      expect(repository.cancelled, ['c1']);
    },
  );

  test(
    'leaving the active group falls back to the oldest remaining one',
    () async {
      final repository = _FakeCircleRepository([
        _summary('c1'),
        _summary('c2'),
      ]);
      final container = await _start(repository);
      final circles = container.listen(circlesProvider('u'), (_, _) {});
      final snapshots = container.listen(
        circleSnapshotProvider('u'),
        (_, _) {},
      );
      addTearDown(circles.close);
      addTearDown(snapshots.close);

      await container.read(circlesProvider('u').future);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(activeCircleControllerProvider('u')), 'c1');

      final preferences = await SharedPreferences.getInstance();
      await container
          .read(activeCircleControllerProvider('u').notifier)
          .leaveCircle('c1');
      await Future<void>.delayed(Duration.zero);

      expect(repository.left, ['c1']);
      expect(container.read(activeCircleControllerProvider('u')), 'c2');
      expect(ActiveCircleStore(preferences).read('u'), 'c2');
      expect(repository.watched, ['c1', 'c2']);
      expect(repository.cancelled, ['c1']);
    },
  );

  test('leaving the only group clears the saved active id', () async {
    final repository = _FakeCircleRepository([_summary('c1')]);
    final container = await _start(repository);
    final circles = container.listen(circlesProvider('u'), (_, _) {});
    addTearDown(circles.close);

    await container.read(circlesProvider('u').future);
    await Future<void>.delayed(Duration.zero);

    final preferences = await SharedPreferences.getInstance();
    await container
        .read(activeCircleControllerProvider('u').notifier)
        .leaveCircle('c1');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeCircleControllerProvider('u')), isNull);
    expect(ActiveCircleStore(preferences).read('u'), isNull);
  });
}
