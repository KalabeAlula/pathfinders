import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:pathfinders/features/pet/domain/ethiopian_pet.dart';
import 'package:pathfinders/features/pet/presentation/widgets/pet_avatar.dart';

Widget _host({required int unreadCount, required VoidCallback onChat}) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DashboardHeader(
          greeting: 'Good morning',
          firstName: 'Kaleab',
          circleName: 'Trail crew',
          dateLine: 'Sunday, Nov 2',
          unreadCount: unreadCount,
          onChat: onChat,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the live unread badge and opens chat', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_host(unreadCount: 4, onChat: () => opened++));

    expect(find.text('4'), findsOneWidget);
    expect(find.byIcon(Icons.forum_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Crew chat'));
    expect(opened, 1);
  });

  testWidgets('hides the badge when everything is seen', (tester) async {
    await tester.pumpWidget(_host(unreadCount: 0, onChat: () {}));

    expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('shows the active group identity without the invite code', (
    tester,
  ) async {
    var opened = 0;
    var petOpened = 0;
    var settingsOpened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DashboardHeader(
              greeting: 'Good morning',
              firstName: 'Kaleab',
              circleName: 'Trail crew',
              dateLine: 'Sunday, Nov 2',
              unreadCount: 0,
              onChat: () {},
              type: GroupType.friends,
              memberCount: 3,
              memberCapacity: 4,
              pet: EthiopianPet.gelada,
              petName: 'Chele',
              onOpenGroups: () => opened++,
              onOpenPet: () => petOpened++,
              onOpenSettings: () => settingsOpened++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Trail crew'), findsOneWidget);
    expect(find.byType(PetAvatar), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('3 of 4 members · Sunday, Nov 2'), findsOneWidget);
    expect(find.text('ABC123'), findsNothing);
    expect(find.text('INVITE'), findsNothing);

    await tester.tap(find.text('Trail crew'));
    expect(opened, 1);

    await tester.tap(find.byType(PetAvatar));
    expect(petOpened, 1);

    await tester.tap(find.byKey(const ValueKey('group-type-pill')));
    expect(settingsOpened, 1);
  });

  testWidgets('the type pill carries an icon for every group kind', (
    tester,
  ) async {
    Future<void> pumpType(GroupType type) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardHeader(
              greeting: 'Good morning',
              firstName: 'Kaleab',
              circleName: 'Trail crew',
              dateLine: 'Sunday, Nov 2',
              unreadCount: 0,
              onChat: () {},
              type: type,
              onOpenSettings: () {},
            ),
          ),
        ),
      );
    }

    await pumpType(GroupType.couple);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('COUPLE'), findsOneWidget);

    await pumpType(GroupType.friends);
    expect(find.byIcon(Icons.groups_rounded), findsOneWidget);

    await pumpType(GroupType.family);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.text('FAMILY'), findsOneWidget);
  });

  testWidgets('fits a 360dp phone at 1.2x text', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.2)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DashboardHeader(
              greeting: 'Good morning',
              firstName: 'Kaleab',
              circleName: 'The Bole Trail Crew',
              dateLine: 'Sunday, Nov 2',
              unreadCount: 12,
              onChat: () {},
              type: GroupType.family,
              memberCount: 6,
              memberCapacity: 6,
              pet: EthiopianPet.waliaIbex,
              petName: 'Walia',
              onOpenGroups: () {},
              onOpenPet: () {},
              onOpenSettings: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('group-type-pill')), findsOneWidget);
  });
}
