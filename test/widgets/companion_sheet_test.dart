import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/core/application/clock_provider.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/pet/application/pet_providers.dart';
import 'package:pathfinders/features/pet/domain/ethiopian_pet.dart';
import 'package:pathfinders/features/pet/domain/pet_care_action.dart';
import 'package:pathfinders/features/pet/domain/pet_repository.dart';
import 'package:pathfinders/features/pet/domain/shared_pet.dart';
import 'package:pathfinders/features/pet/presentation/widgets/companion_sheet.dart';

final _now = DateTime(2026, 11, 3, 9);

class _FakePetRepository implements PetRepository {
  final cared = <PetCareAction>[];

  @override
  Future<SharedPet> care(PetCareAction action) async {
    cared.add(action);
    return SharedPet(
      name: 'Walia',
      species: 'walia_ibex',
      level: 2,
      experience: 140,
      hunger: 80,
      energy: 80,
      hygiene: 80,
      happiness: 82,
      updatedAt: _now,
    );
  }
}

Circle _circle() {
  return Circle(
    id: 'c1',
    name: 'Family Table',
    inviteCode: 'PF-9K2Q',
    memberIds: const ['u1'],
    createdAt: _now,
    type: GroupType.family,
    petId: 'walia_ibex',
    petName: 'Walia',
    petLevel: 2,
    petExperience: 140,
    petHunger: 80,
    petEnergy: 80,
    petHygiene: 80,
    petHappiness: 82,
    petUpdatedAt: _now,
  );
}

Future<List<PetCareAction>> pumpCard(WidgetTester tester) async {
  final repository = _FakePetRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appClockProvider.overrideWith((_) => Stream.value(_now)),
        circleSnapshotProvider('u1').overrideWith(
          (_) => Stream.value(CircleSnapshot(circle: _circle(), members: const [])),
        ),
        petRepositoryProvider('c1').overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompanionCard(
              circleId: 'c1',
              currentUserId: 'u1',
              pet: EthiopianPet.waliaIbex,
              groupType: GroupType.family,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return repository.cared;
}

void main() {
  testWidgets('shows species, habitat, level, and care stats', (tester) async {
    await pumpCard(tester);

    expect(find.text('Walia'), findsOneWidget);
    expect(find.text('Walia Ibex'), findsOneWidget);
    expect(find.text('ዋልያ · Resting'), findsOneWidget);
    expect(find.text('Native to Simien Mountains cliffs'), findsOneWidget);
    expect(find.text('FAMILY'), findsOneWidget);
    expect(find.text(EthiopianPet.waliaIbex.funFact), findsOneWidget);
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('60 XP to level 3'), findsOneWidget);
    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
  });

  testWidgets('care buttons reach the circle pet repository', (tester) async {
    final cared = await pumpCard(tester);

    expect(find.byTooltip('Feed Walia'), findsOneWidget);
    expect(find.byTooltip('Clean Walia'), findsOneWidget);
    expect(find.byTooltip('Play Walia'), findsOneWidget);

    await tester.tap(find.byTooltip('Play Walia'));
    await tester.pump();

    expect(cared, [PetCareAction.play]);
  });
}
