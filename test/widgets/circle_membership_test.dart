import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/data/active_circle_store.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_failure.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/circle_repository.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/circle/domain/circle_summary.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/circle/presentation/widgets/circle_settings_sheet.dart';
import 'package:pathfinders/features/circle/presentation/widgets/join_circle_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

CircleMember _member(String id, String name) {
  return CircleMember(
    profile: UserProfile(id: id, displayName: name, avatarColor: 0xFF3B7C6C),
    status: null,
  );
}

CircleSnapshot _snapshot({
  required String createdBy,
  List<CircleMember>? members,
}) {
  return CircleSnapshot(
    circle: Circle(
      id: 'c1',
      name: 'Trail crew',
      inviteCode: 'ABC123',
      memberIds: const ['u', 'owner'],
      createdAt: DateTime(2026, 1, 1),
      createdBy: createdBy,
      petId: 'gelada',
      petName: 'Chele',
    ),
    members:
        members ??
        [_member('u', 'Kaleab Bekele'), _member('owner', 'Marta Alemu')],
  );
}

class _FakeCircleRepository implements CircleRepository {
  _FakeCircleRepository({
    List<CircleSummary> summaries = const [],
    this.joinResult,
    this.joinFailure,
  }) : summaries = [...summaries];

  final List<CircleSummary> summaries;
  final Circle? joinResult;
  final Object? joinFailure;
  final List<String> joinedCodes = [];
  final List<String> left = [];
  final List<String> deleted = [];
  final List<({String circleId, String name})> renames = [];
  final List<String> rotations = [];
  final List<({String circleId, String memberId})> removedMembers = [];
  final List<({String circleId, String newOwnerId})> transfers = [];
  String rotatedCode = 'NEW234';
  Stream<CircleSnapshot?>? snapshotStream;
  final _summaries = StreamController<List<CircleSummary>>.broadcast();

  void dispose() => _summaries.close();

  /// Pushes the current [summaries] like a realtime membership change would.
  void emitSummaries() {
    if (!_summaries.isClosed) _summaries.add(List.of(summaries));
  }

  @override
  Stream<List<CircleSummary>> watchCircles() {
    scheduleMicrotask(() {
      if (!_summaries.isClosed) _summaries.add(List.of(summaries));
    });
    return _summaries.stream;
  }

  @override
  Stream<CircleSnapshot?> watchCircle(String circleId) =>
      snapshotStream ?? Stream<CircleSnapshot?>.value(null);

  @override
  Future<Circle> createCircle({
    required String name,
    required GroupType type,
    required String petId,
    required String petName,
  }) => throw UnimplementedError();

  @override
  Future<Circle> joinCircle({required String code}) async {
    joinedCodes.add(code);
    final failure = joinFailure;
    if (failure != null) throw failure;
    final circle = joinResult!;
    summaries.add(
      CircleSummary(
        id: circle.id,
        name: circle.name,
        type: circle.type,
        memberCount: circle.memberIds.length,
        createdAt: circle.createdAt,
      ),
    );
    return circle;
  }

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
  }) async {
    renames.add((circleId: circleId, name: name));
  }

  @override
  Future<String> rotateInviteCode({required String circleId}) async {
    rotations.add(circleId);
    return rotatedCode;
  }

  @override
  Future<void> removeMember({
    required String circleId,
    required String memberId,
  }) async {
    removedMembers.add((circleId: circleId, memberId: memberId));
  }

  @override
  Future<void> transferOwnership({
    required String circleId,
    required String newOwnerId,
  }) async {
    transfers.add((circleId: circleId, newOwnerId: newOwnerId));
  }
}

class _JoinHost extends StatelessWidget {
  const _JoinHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showJoinCircleSheet(context, userId: 'u'),
            child: const Text('Open join'),
          ),
        ),
      ),
    );
  }
}

class _SettingsHost extends StatelessWidget {
  const _SettingsHost({required this.snapshot});

  final CircleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () =>
                showCircleSettings(context, userId: 'u', snapshot: snapshot),
            child: const Text('Open details'),
          ),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _FakeCircleRepository repository,
  Widget home,
) async {
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        circleRepositoryProvider('u').overrideWithValue(repository),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('joins with an uppercase code and switches to the new circle', (
    tester,
  ) async {
    final repository = _FakeCircleRepository(
      joinResult: Circle(
        id: 'c9',
        name: 'Sunrise Riders',
        inviteCode: 'A2B3C4',
        memberIds: const ['u', 'owner'],
        createdAt: DateTime(2026, 2, 1),
        type: GroupType.friends,
      ),
    );
    addTearDown(repository.dispose);

    await _pump(tester, repository, const _JoinHost());
    await tester.tap(find.text('Open join'));
    await tester.pumpAndSettle();

    expect(find.text('Join a Circle'), findsOneWidget);
    expect(
      find.text('Enter the invite code shared by your circle creator.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const ValueKey('join-code')), 'a2b3c4');
    await tester.tap(find.byKey(const ValueKey('join-submit')));
    await tester.pumpAndSettle();

    expect(repository.joinedCodes, ['A2B3C4']);
    expect(find.text('Welcome to Sunrise Riders!'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(ActiveCircleStore(preferences).read('u'), 'c9');
  });

  testWidgets('rejects a short invite code before calling the backend', (
    tester,
  ) async {
    final repository = _FakeCircleRepository();
    addTearDown(repository.dispose);

    await _pump(tester, repository, const _JoinHost());
    await tester.tap(find.text('Open join'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('join-code')), 'A2B');
    await tester.tap(find.byKey(const ValueKey('join-submit')));
    await tester.pumpAndSettle();

    expect(repository.joinedCodes, isEmpty);
    expect(find.text('Invite codes are six characters.'), findsOneWidget);
  });

  testWidgets('surfaces a full-circle failure from the backend', (
    tester,
  ) async {
    final repository = _FakeCircleRepository(
      joinFailure: const CircleFailure('That circle is full.'),
    );
    addTearDown(repository.dispose);

    await _pump(tester, repository, const _JoinHost());
    await tester.tap(find.text('Open join'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('join-code')), 'A2B3C4');
    await tester.tap(find.byKey(const ValueKey('join-submit')));
    await tester.pumpAndSettle();

    expect(repository.joinedCodes, ['A2B3C4']);
    expect(find.text('That circle is full.'), findsOneWidget);
    expect(find.text('Join a Circle'), findsOneWidget);
  });

  testWidgets('a member can leave, which pops the sheet', (tester) async {
    final repository = _FakeCircleRepository(
      summaries: [
        CircleSummary(
          id: 'c1',
          name: 'Trail crew',
          type: GroupType.friends,
          memberCount: 2,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(snapshot: _snapshot(createdBy: 'owner')),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('Circle details'), findsOneWidget);
    expect(find.byKey(const ValueKey('leave-circle')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-circle')), findsNothing);
    expect(find.byKey(const ValueKey('rename-circle')), findsNothing);
    expect(find.byKey(const ValueKey('rotate-invite-code')), findsNothing);
    expect(find.byKey(const ValueKey('transfer-ownership')), findsNothing);
    expect(find.byKey(const ValueKey('member-menu-owner')), findsNothing);

    final leave = find.byKey(const ValueKey('leave-circle'));
    await tester.ensureVisible(leave);
    await tester.tap(leave);
    await tester.pumpAndSettle();

    expect(find.text('Leave Trail crew?'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(repository.left, ['c1']);
    expect(find.text('You left Trail crew.'), findsOneWidget);
    expect(find.text('Circle details'), findsNothing);
  });

  testWidgets('the creator deletes the circle after confirming', (
    tester,
  ) async {
    final repository = _FakeCircleRepository(
      summaries: [
        CircleSummary(
          id: 'c1',
          name: 'Trail crew',
          type: GroupType.friends,
          memberCount: 2,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(snapshot: _snapshot(createdBy: 'u')),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete-circle')), findsOneWidget);
    expect(find.byKey(const ValueKey('leave-circle')), findsNothing);

    final delete = find.byKey(const ValueKey('delete-circle'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();

    expect(find.text('Delete Trail crew?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deleted, ['c1']);
    expect(find.text('Trail crew was deleted.'), findsOneWidget);
  });

  testWidgets('the creator renames the circle and empty names are rejected', (
    tester,
  ) async {
    final repository = _FakeCircleRepository();
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(snapshot: _snapshot(createdBy: 'u')),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rename-circle')));
    await tester.pumpAndSettle();

    expect(find.text('Rename circle'), findsOneWidget);
    final field = find.byKey(const ValueKey('circle-name-field'));

    await tester.enterText(field, '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Give your circle a name.'), findsOneWidget);
    expect(repository.renames, isEmpty);

    await tester.enterText(field, 'Entoto House');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.renames, hasLength(1));
    expect(repository.renames.single.circleId, 'c1');
    expect(repository.renames.single.name, 'Entoto House');
    expect(find.text('Rename circle'), findsNothing);
    expect(find.text('Circle details'), findsOneWidget);
    expect(find.text('Entoto House'), findsOneWidget);
    expect(find.text('Trail crew'), findsNothing);
    expect(find.text('Circle renamed to Entoto House.'), findsOneWidget);
  });

  testWidgets('the creator rotates the invite code after confirming', (
    tester,
  ) async {
    final repository = _FakeCircleRepository();
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(snapshot: _snapshot(createdBy: 'u')),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    final rotate = find.byKey(const ValueKey('rotate-invite-code'));
    await tester.ensureVisible(rotate);
    await tester.tap(rotate);
    await tester.pumpAndSettle();

    expect(find.text('Rotate invite code?'), findsOneWidget);
    await tester.tap(find.text('Rotate'));
    await tester.pumpAndSettle();

    expect(repository.rotations, ['c1']);
    expect(find.text('NEW234'), findsOneWidget);
    expect(find.text('ABC123'), findsNothing);
    expect(
      find.text('New invite code ready. The old code no longer works.'),
      findsOneWidget,
    );
  });

  testWidgets('the creator removes another member after confirming', (
    tester,
  ) async {
    final repository = _FakeCircleRepository();
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(snapshot: _snapshot(createdBy: 'u')),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 4 members'), findsOneWidget);
    expect(find.byKey(const ValueKey('member-menu-u')), findsNothing);

    final menu = find.byKey(const ValueKey('member-menu-owner'));
    expect(menu, findsOneWidget);
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove from circle'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Marta?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(repository.removedMembers, [(circleId: 'c1', memberId: 'owner')]);
    expect(find.text('Marta Alemu'), findsNothing);
    expect(find.text('1 of 4 members'), findsOneWidget);
    expect(find.text('Marta was removed from Trail crew.'), findsOneWidget);
  });

  testWidgets('the creator transfers ownership and becomes a member', (
    tester,
  ) async {
    final repository = _FakeCircleRepository();
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(snapshot: _snapshot(createdBy: 'u')),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    final transfer = find.byKey(const ValueKey('transfer-ownership'));
    await tester.ensureVisible(transfer);
    await tester.tap(transfer);
    await tester.pumpAndSettle();

    expect(find.text('Transfer ownership'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('transfer-owner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-transfer')));
    await tester.pumpAndSettle();

    expect(repository.transfers, [(circleId: 'c1', newOwnerId: 'owner')]);
    expect(
      find.text('Marta is now the creator of Trail crew.'),
      findsOneWidget,
    );
    expect(find.text('Creator'), findsOneWidget);
    expect(find.text('Marta Alemu'), findsOneWidget);

    expect(find.byKey(const ValueKey('delete-circle')), findsNothing);
    expect(find.byKey(const ValueKey('rename-circle')), findsNothing);
    expect(find.byKey(const ValueKey('rotate-invite-code')), findsNothing);
    expect(find.byKey(const ValueKey('transfer-ownership')), findsNothing);
    expect(find.byKey(const ValueKey('member-menu-owner')), findsNothing);
    expect(find.byKey(const ValueKey('leave-circle')), findsOneWidget);
  });

  testWidgets('transfer with no other members asks the creator to invite', (
    tester,
  ) async {
    final repository = _FakeCircleRepository();
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(
        snapshot: _snapshot(
          createdBy: 'u',
          members: [_member('u', 'Kaleab Bekele')],
        ),
      ),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    final transfer = find.byKey(const ValueKey('transfer-ownership'));
    await tester.ensureVisible(transfer);
    await tester.tap(transfer);
    await tester.pumpAndSettle();

    expect(
      find.text('Invite someone before transferring ownership.'),
      findsOneWidget,
    );
    expect(find.text('Transfer ownership'), findsNothing);
    expect(repository.transfers, isEmpty);
  });

  testWidgets(
    'a transfer on another device swaps the open sheet to member view',
    (tester) async {
      final repository = _FakeCircleRepository(
        summaries: [
          CircleSummary(
            id: 'c1',
            name: 'Trail crew',
            type: GroupType.friends,
            memberCount: 2,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      final live = StreamController<CircleSnapshot?>.broadcast();
      repository.snapshotStream = live.stream;
      addTearDown(live.close);
      addTearDown(repository.dispose);

      await _pump(
        tester,
        repository,
        _SettingsHost(snapshot: _snapshot(createdBy: 'u')),
      );
      await tester.tap(find.text('Open details'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('delete-circle')), findsOneWidget);

      live.add(_snapshot(createdBy: 'owner'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('delete-circle')), findsNothing);
      expect(find.byKey(const ValueKey('transfer-ownership')), findsNothing);
      expect(find.byKey(const ValueKey('rename-circle')), findsNothing);
      expect(find.byKey(const ValueKey('rotate-invite-code')), findsNothing);
      expect(find.byKey(const ValueKey('member-menu-owner')), findsNothing);
      expect(find.byKey(const ValueKey('leave-circle')), findsOneWidget);
      expect(find.text('Creator'), findsOneWidget);
    },
  );

  testWidgets('being made creator brings the owner tools into the open sheet', (
    tester,
  ) async {
    final repository = _FakeCircleRepository(
      summaries: [
        CircleSummary(
          id: 'c1',
          name: 'Trail crew',
          type: GroupType.friends,
          memberCount: 2,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    final live = StreamController<CircleSnapshot?>.broadcast();
    repository.snapshotStream = live.stream;
    addTearDown(live.close);
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(snapshot: _snapshot(createdBy: 'owner')),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('leave-circle')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-circle')), findsNothing);

    live.add(_snapshot(createdBy: 'u'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete-circle')), findsOneWidget);
    expect(find.byKey(const ValueKey('transfer-ownership')), findsOneWidget);
    expect(find.byKey(const ValueKey('rename-circle')), findsOneWidget);
    expect(find.byKey(const ValueKey('rotate-invite-code')), findsOneWidget);
    expect(find.byKey(const ValueKey('leave-circle')), findsNothing);
  });

  testWidgets('losing this circle closes the open details sheet', (
    tester,
  ) async {
    final repository = _FakeCircleRepository(
      summaries: [
        CircleSummary(
          id: 'c1',
          name: 'Trail crew',
          type: GroupType.friends,
          memberCount: 2,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    addTearDown(repository.dispose);

    await _pump(
      tester,
      repository,
      _SettingsHost(snapshot: _snapshot(createdBy: 'owner')),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    expect(find.text('Circle details'), findsOneWidget);

    repository.summaries.clear();
    repository.emitSummaries();
    await tester.pumpAndSettle();

    expect(find.text('Circle details'), findsNothing);
    expect(find.text('Open details'), findsOneWidget);
  });
}
