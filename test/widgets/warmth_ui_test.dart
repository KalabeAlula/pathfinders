import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/features/circle/domain/circle_member.dart';
import 'package:pathfinders/features/circle/domain/group_type.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/circle/presentation/widgets/member_card.dart';
import 'package:pathfinders/features/nudges/domain/nudge.dart';
import 'package:pathfinders/features/nudges/presentation/widgets/warmth_banner.dart';
import 'package:pathfinders/features/nudges/presentation/widgets/warmth_picker.dart';

const _profile = UserProfile(
  id: 'alex',
  displayName: 'Alex Bekele',
  avatarColor: 0xFFB86B4F,
);

void main() {
  group('warmth picker', () {
    Future<void> openPicker(
      WidgetTester tester,
      GroupType type, {
      required ValueChanged<NudgeWarmth?> onChosen,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  onChosen(
                    await showWarmthPicker(
                      context,
                      type: type,
                      memberName: 'Alex',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('couples see only romantic actions', (tester) async {
      NudgeWarmth? chosen;
      await openPicker(
        tester,
        GroupType.couple,
        onChosen: (warmth) => chosen = warmth,
      );

      expect(find.text('Send Alex some warmth'), findsOneWidget);
      expect(find.text('Kiss'), findsOneWidget);
      expect(find.text('Hug'), findsOneWidget);
      expect(find.text('Thinking of you'), findsOneWidget);
      expect(find.text('Love you'), findsOneWidget);
      expect(find.text('High five'), findsNothing);
      expect(find.text('Check-in'), findsNothing);

      await tester.tap(find.text('Kiss'));
      await tester.pumpAndSettle();
      expect(chosen, NudgeWarmth.kiss);
    });

    testWidgets('friends never see a kiss option', (tester) async {
      NudgeWarmth? chosen;
      await openPicker(
        tester,
        GroupType.friends,
        onChosen: (warmth) => chosen = warmth,
      );

      expect(find.text('High five'), findsOneWidget);
      expect(find.text('Fist bump'), findsOneWidget);
      expect(find.text('Wave'), findsOneWidget);
      expect(find.text('Where you at?'), findsOneWidget);
      expect(find.text('Kiss'), findsNothing);

      await tester.tap(find.text('Wave'));
      await tester.pumpAndSettle();
      expect(chosen, NudgeWarmth.wave);
    });

    testWidgets('families see checking-in warmth', (tester) async {
      NudgeWarmth? chosen;
      await openPicker(
        tester,
        GroupType.family,
        onChosen: (warmth) => chosen = warmth,
      );

      expect(find.text('Warm hug'), findsOneWidget);
      expect(find.text('Check-in'), findsOneWidget);
      expect(find.text('Thinking of you'), findsOneWidget);
      expect(find.text('High five'), findsNothing);

      await tester.tap(find.text('Check-in'));
      await tester.pumpAndSettle();
      expect(chosen, NudgeWarmth.checkIn);
    });
  });

  group('warmth banner', () {
    testWidgets('shows the emoji and personalized message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: WarmthBanner(
              emoji: '😘',
              message: 'Alex sent you a sweet kiss!',
              isIncoming: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const ValueKey('warmth-banner')), findsOneWidget);
      expect(find.text('😘'), findsOneWidget);
      expect(find.text('Alex sent you a sweet kiss!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('member card warmth', () {
    Future<void> pumpPeer(
      WidgetTester tester, {
      required VoidCallback onWarmth,
      required VoidCallback onWarmthOptions,
      String? warmthEmoji = '😘',
      bool isCurrentUser = false,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 116,
                child: MemberCard(
                  member: const CircleMember(profile: _profile, status: null),
                  isCurrentUser: isCurrentUser,
                  now: DateTime(2026, 11, 4, 12),
                  onTap: () {},
                  warmthEmoji: warmthEmoji,
                  onWarmth: onWarmth,
                  onWarmthOptions: onWarmthOptions,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('a quick tap sends the default warmth', (tester) async {
      var quick = 0;
      var options = 0;
      await pumpPeer(
        tester,
        onWarmth: () => quick++,
        onWarmthOptions: () => options++,
      );

      expect(find.text('😘'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('warmth-alex')));
      expect(quick, 1);
      expect(options, 0);
    });

    testWidgets('holding the button opens the options', (tester) async {
      var quick = 0;
      var options = 0;
      await pumpPeer(
        tester,
        onWarmth: () => quick++,
        onWarmthOptions: () => options++,
      );

      await tester.longPress(find.byKey(const ValueKey('warmth-alex')));
      expect(options, 1);
      expect(quick, 0);
    });

    testWidgets('your own card has no warmth button', (tester) async {
      await pumpPeer(
        tester,
        isCurrentUser: true,
        warmthEmoji: null,
        onWarmth: () {},
        onWarmthOptions: () {},
      );

      expect(find.byKey(const ValueKey('warmth-alex')), findsNothing);
    });
  });
}
