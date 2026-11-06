import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/features/circle/application/circle_providers.dart';
import 'package:pathfinders/features/circle/domain/circle.dart';
import 'package:pathfinders/features/circle/domain/circle_snapshot.dart';
import 'package:pathfinders/features/navigation/application/arrival_controller.dart';
import 'package:pathfinders/features/navigation/application/navigation_providers.dart';
import 'package:pathfinders/features/navigation/domain/navigation_destination.dart'
    as nav;
import 'package:pathfinders/features/navigation/domain/navigation_repository.dart';
import 'package:pathfinders/features/navigation/presentation/widgets/arrival_card.dart';
import 'package:pathfinders/features/pet/domain/pet_mood.dart';
import 'package:pathfinders/features/pet/presentation/widgets/animated_pet_sticker.dart';
import 'package:pathfinders/features/pet/presentation/widgets/pet_avatar.dart';

class _FakeRepository implements NavigationRepository {
  int clears = 0;

  @override
  Future<void> clearDestination() async => clears++;

  @override
  Future<void> setDestination({
    required String label,
    required double latitude,
    required double longitude,
    required String setBy,
  }) async {}

  @override
  Stream<nav.NavigationDestination?> watchDestination() =>
      Stream<nav.NavigationDestination?>.value(null);
}

void main() {
  final now = DateTime(2026, 11, 5, 18);
  final destination = nav.NavigationDestination(
    latitude: 9.03,
    longitude: 38.74,
    label: 'Entoto Ridge',
    setBy: 'u1',
    updatedAt: now,
  );

  Widget host({
    required bool arrived,
    bool everyoneArrived = false,
    NavigationRepository? repository,
  }) {
    final snapshot = CircleSnapshot(
      circle: Circle(
        id: 'c1',
        name: 'Trail Crew',
        inviteCode: 'PF-9K2Q',
        memberIds: const ['u1'],
        createdAt: now,
        petId: 'gelada',
        petName: 'Desta',
      ),
      members: const [],
    );

    return ProviderScope(
      overrides: [
        arrivalControllerProvider('c1').overrideWithValue(
          ArrivalState(
            destination: destination,
            distanceMeters: arrived ? 12 : 800,
            arrived: arrived,
            everyoneArrived: everyoneArrived,
          ),
        ),
        circleSnapshotProvider('u1')
            .overrideWith((_) => Stream.value(snapshot)),
        if (repository != null)
          navigationRepositoryProvider('c1').overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ArrivalCard(circleId: 'c1', currentUserId: 'u1'),
        ),
      ),
    );
  }

  testWidgets('celebrates arrival with the circle companion sticker', (
    tester,
  ) async {
    await tester.pumpWidget(host(arrived: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("You've arrived at Entoto Ridge"), findsOneWidget);

    final sticker = tester.widget<AnimatedPetSticker>(
      find.byType(AnimatedPetSticker),
    );
    expect(sticker.mood, PetMood.celebrating);
    expect(sticker.pet.id, 'gelada');
    expect(find.byType(PetAvatar), findsOneWidget);
  });

  testWidgets('stays hidden until the crew arrives', (tester) async {
    await tester.pumpWidget(host(arrived: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ArrivalCard), findsOneWidget);
    expect(find.byType(AnimatedPetSticker), findsNothing);
  });

  testWidgets('says the trip wraps up on its own once everyone is here', (
    tester,
  ) async {
    await tester.pumpWidget(host(arrived: true, everyoneArrived: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("Everyone's here. Ending soon."), findsOneWidget);
    expect(find.text('End now'), findsOneWidget);
  });

  testWidgets('End now clears the trip without waiting for the grace', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      host(arrived: true, everyoneArrived: true, repository: repository),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('End now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.clears, 1);
    expect(find.text('Navigation ended.'), findsOneWidget);
  });
}
