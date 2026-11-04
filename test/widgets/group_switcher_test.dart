import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:pathfinders/features/circle/presentation/create_group_screen.dart';
import 'package:pathfinders/features/circle/presentation/widgets/group_switcher_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

CircleSummary _summary(
  String id, {
  required String name,
  GroupType type = GroupType.friends,
  int members = 1,
  String petId = 'gelada',
  String petName = 'Momo',
}) {
  return CircleSummary(
    id: id,
    name: name,
    type: type,
    memberCount: members,
    createdAt: DateTime(2026, 1, 1),
    petId: petId,
    petName: petName,
  );
}

class _FakeCircleRepository implements CircleRepository {
  _FakeCircleRepository(this.summaries);

  final List<CircleSummary> summaries;
  final _summaries = StreamController<List<CircleSummary>>.broadcast();
  final List<({String name, GroupType type, String petId, String petName})>
  created = [];

  void dispose() {
    _summaries.close();
  }

  @override
  Stream<List<CircleSummary>> watchCircles() {
    scheduleMicrotask(() {
      if (!_summaries.isClosed) _summaries.add(summaries);
    });
    return _summaries.stream;
  }

  @override
  Stream<CircleSnapshot?> watchCircle(String circleId) => Stream.value(null);

  @override
  Future<Circle> createCircle({
    required String name,
    required GroupType type,
    required String petId,
    required String petName,
  }) async {
    created.add((name: name, type: type, petId: petId, petName: petName));
    return Circle(
      id: 'new-group',
      name: name,
      inviteCode: 'ABC234',
      memberIds: const ['u'],
      createdAt: DateTime(2026, 1, 1),
      type: type,
      petId: petId,
      petName: petName,
    );
  }

  @override
  Future<Circle> joinCircle({required String code}) =>
      throw UnimplementedError();

  @override
  Future<void> leaveCircle({required String circleId}) async {}

  @override
  Future<void> deleteCircle({required String circleId}) async {}

  @override
  Future<void> renameCircle({
    required String circleId,
    required String name,
  }) async {}

  @override
  Future<String> rotateInviteCode({required String circleId}) async => 'NEW234';
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showGroupSwitcher(context, userId: 'u'),
            child: const Text('Open groups'),
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

  testWidgets('shows every group and switches the active one', (tester) async {
    final repository = _FakeCircleRepository([
      _summary('c1', name: 'Bole Crew', members: 3),
      _summary(
        'c2',
        name: 'Family Table',
        type: GroupType.family,
        members: 5,
        petId: 'lion',
        petName: 'Anbessa',
      ),
    ]);
    addTearDown(repository.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(tester, repository, const _Host());
    await tester.tap(find.text('Open groups'));
    await tester.pumpAndSettle();

    expect(find.text('Your groups'), findsOneWidget);
    expect(find.text('Bole Crew'), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('3 of 4 members · Gelada Momo'), findsOneWidget);
    expect(find.text('FAMILY'), findsOneWidget);
    expect(
      find.text('5 of 6 members · Black-maned Ethiopian Lion Anbessa'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.text('Family Table'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(ActiveCircleStore(preferences).read('u'), 'c2');
    expect(find.text('Your groups'), findsNothing);
  });

  testWidgets('Create Circle opens the four-step flow', (tester) async {
    final repository = _FakeCircleRepository([
      _summary('c1', name: 'Bole Crew'),
    ]);
    addTearDown(repository.dispose);

    await _pump(tester, repository, const _Host());
    await tester.tap(find.text('Open groups'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Circle'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateGroupScreen), findsOneWidget);
    expect(find.text('Name your group'), findsOneWidget);
    expect(find.text('Step 1 of 4 · Name it'), findsOneWidget);
  });

  testWidgets('creates a family group with the chosen companion', (
    tester,
  ) async {
    final repository = _FakeCircleRepository([
      _summary('c1', name: 'Bole Crew'),
    ]);
    addTearDown(repository.dispose);

    await _pump(tester, repository, const CreateGroupScreen(userId: 'u'));

    await tester.enterText(
      find.byKey(const ValueKey('group-name')),
      'Entoto House',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Choose the shape'), findsOneWidget);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Pick a companion'), findsOneWidget);
    await tester.tap(find.text('Black-maned Ethiopian Lion'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pet-name')), 'Saba');
    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.name, 'Entoto House');
    expect(repository.created.single.type, GroupType.family);
    expect(repository.created.single.petId, 'lion');
    expect(repository.created.single.petName, 'Saba');
    expect(find.text('“Entoto House” is ready'), findsOneWidget);
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.text('Open group'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(ActiveCircleStore(preferences).read('u'), 'new-group');
  });
}
