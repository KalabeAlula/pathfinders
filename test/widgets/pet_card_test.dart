import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/pet/domain/ethiopian_pet.dart';
import 'package:pathfinders/features/pet/domain/pet_care_action.dart';
import 'package:pathfinders/features/pet/domain/shared_pet.dart';
import 'package:pathfinders/features/pet/presentation/widgets/companion_sheet.dart';
import 'package:pathfinders/features/pet/presentation/widgets/pet_avatar.dart';
import 'package:pathfinders/features/pet/presentation/widgets/pet_card.dart';

final _now = DateTime(2026, 11, 3, 9);

SharedPet _pet({String species = 'ethiopian_wolf', String name = 'Sene'}) {
  return SharedPet(
    name: name,
    species: species,
    level: 2,
    experience: 140,
    hunger: 80,
    energy: 80,
    hygiene: 80,
    happiness: 82,
    updatedAt: _now,
  );
}

Widget _host(SharedPet pet, ValueChanged<PetCareAction> onCare) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 164,
        child: PetCard(pet: pet, now: _now, onCare: onCare),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the Ethiopian companion and names it in care tooltips', (
    tester,
  ) async {
    PetCareAction? tapped;
    await tester.pumpWidget(_host(_pet(), (action) => tapped = action));

    expect(find.text('Sene'), findsOneWidget);
    expect(
      find.text('Sene is glowing — the whole crew showed up today.'),
      findsOneWidget,
    );
    expect(find.byType(PetAvatar), findsOneWidget);
    expect(find.byTooltip('Meet Sene'), findsOneWidget);

    await tester.tap(find.byTooltip('Play Sene'));
    expect(tapped, PetCareAction.play);
  });

  testWidgets('opens the companion card from the badge', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 164,
            child: PetCard(
              pet: _pet(species: 'gelada', name: 'Chele'),
              now: _now,
              onCare: (_) {},
              onOpen: () => opened++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PetAvatar));
    expect(opened, 1);
    expect(find.byTooltip('Feed Chele'), findsOneWidget);
  });

  testWidgets('companion card shows species, habitat, and level', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionCard(
            pet: EthiopianPet.waliaIbex,
            state: _pet(species: 'walia_ibex', name: 'Walia'),
            groupType: GroupType.family,
            now: _now,
          ),
        ),
      ),
    );

    expect(find.text('Walia'), findsOneWidget);
    expect(find.text('Walia Ibex'), findsOneWidget);
    expect(find.text('ዋልያ · Happy'), findsOneWidget);
    expect(find.text('Native to Simien Mountains cliffs'), findsOneWidget);
    expect(find.text('FAMILY'), findsOneWidget);
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('60 XP to level 3'), findsOneWidget);
    expect(find.text(EthiopianPet.waliaIbex.funFact), findsOneWidget);
  });
}
