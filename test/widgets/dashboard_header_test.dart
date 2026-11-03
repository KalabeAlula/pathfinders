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
          inviteCode: 'ABC123',
          onCopyInvite: () {},
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

  testWidgets('shows the active group identity and opens the switcher', (
    tester,
  ) async {
    var opened = 0;
    var petOpened = 0;
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
              inviteCode: 'ABC123',
              onCopyInvite: () {},
              unreadCount: 0,
              onChat: () {},
              type: GroupType.friends,
              memberCount: 3,
              memberCapacity: 4,
              pet: EthiopianPet.gelada,
              petName: 'Chele',
              onOpenGroups: () => opened++,
              onOpenPet: () => petOpened++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Trail crew'), findsOneWidget);
    expect(find.byType(PetAvatar), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('3 of 4 members · Sunday, Nov 2'), findsOneWidget);

    await tester.tap(find.text('Trail crew'));
    expect(opened, 1);

    await tester.tap(find.byType(PetAvatar));
    expect(petOpened, 1);
  });
}
