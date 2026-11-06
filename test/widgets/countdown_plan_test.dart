import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/chat/application/chat_providers.dart';
import 'package:pathfinders/features/chat/domain/chat_message.dart';
import 'package:pathfinders/features/chat/domain/chat_repository.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/milestones/application/milestones_providers.dart';
import 'package:pathfinders/features/milestones/domain/milestones_failure.dart';
import 'package:pathfinders/features/milestones/domain/milestones_repository.dart';
import 'package:pathfinders/features/milestones/domain/shared_milestone.dart';
import 'package:pathfinders/features/milestones/presentation/widgets/countdown_card.dart';
import 'package:pathfinders/features/milestones/presentation/widgets/milestone_plan_sheet.dart';
import 'package:pathfinders/features/navigation/application/navigation_providers.dart';
import 'package:pathfinders/features/navigation/domain/navigation_gateway.dart';
import 'package:pathfinders/features/navigation/domain/place_suggestion.dart';
import 'package:pathfinders/features/navigation/domain/route_plan.dart';

final _milestone = SharedMilestone(
  id: 's1',
  title: 'Weekend at Langano',
  date: DateTime(2026, 11, 20),
  kind: MilestoneKind.trip,
  startsAt: DateTime(2026, 11, 20, 19),
  place: 'Langano Lake',
  subtitle: 'Bring the guitar',
  createdBy: 'u1',
);

final _milestoneNoPlace = SharedMilestone(
  id: 's2',
  title: 'Game night',
  date: DateTime(2026, 11, 21),
  kind: MilestoneKind.goal,
);

class _FakeMilestonesRepository implements MilestonesRepository {
  _FakeMilestonesRepository({this.failure});

  final MilestonesFailure? failure;
  final places = <({String milestoneId, String? place})>[];
  final times = <({String milestoneId, DateTime? startsAt})>[];
  final deleted = <String>[];

  @override
  Stream<List<SharedMilestone>> watchMilestones() =>
      Stream.value(const <SharedMilestone>[]);

  @override
  Future<void> addMilestone({
    required String createdBy,
    required String title,
    required DateTime date,
    required MilestoneKind kind,
    String? subtitle,
    DateTime? startsAt,
    String? place,
  }) async {}

  @override
  Future<void> setPlace({
    required String milestoneId,
    required String? place,
  }) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    places.add((milestoneId: milestoneId, place: place));
  }

  @override
  Future<void> setStartTime({
    required String milestoneId,
    required DateTime? startsAt,
  }) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    times.add((milestoneId: milestoneId, startsAt: startsAt));
  }

  @override
  Future<void> deleteMilestone(String milestoneId) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    deleted.add(milestoneId);
  }
}

class _FakeNavigationGateway implements NavigationGateway {
  _FakeNavigationGateway({this.spots = const []});

  final List<PlaceSuggestion> spots;
  final queries = <String>[];

  @override
  bool get isConfigured => true;

  @override
  Future<RoutePlan> route({
    required GeoPoint from,
    required GeoPoint to,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    GeoPoint? proximity,
  }) async {
    queries.add(query);
    return spots;
  }

  @override
  Future<String?> reverseGeocode(GeoPoint point) async => null;
}

class _FakeChatRepository implements ChatRepository {
  final sent = <String>[];

  @override
  Stream<List<ChatMessage>> watchMessages() => Stream.value(const []);

  @override
  Future<void> sendText({
    required String senderId,
    required String text,
  }) async {
    sent.add(text);
  }

  @override
  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
  }) async {}
}

Widget _host({
  required _FakeChatRepository chat,
  required DateTime now,
  required bool openPlanOnTap,
  _FakeNavigationGateway? navigation,
  _FakeMilestonesRepository? milestones,
  void Function(GeoPoint point, String label)? onPlanMeetup,
  SharedMilestone? milestone,
}) {
  final target = milestone ?? _milestone;
  return ProviderScope(
    overrides: [
      chatRepositoryProvider('c1').overrideWithValue(chat),
      if (navigation != null)
        navigationGatewayProvider.overrideWithValue(navigation),
      if (milestones != null)
        milestonesRepositoryProvider('c1').overrideWithValue(milestones),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 292,
            height: 128,
            child: Builder(
              builder: (context) => CountdownCard(
                milestone: target,
                now: now,
                onTap: openPlanOnTap
                    ? () => showMilestonePlan(
                        context,
                        circleId: 'c1',
                        currentUserId: 'u1',
                        milestone: target,
                        now: now,
                        onPlanMeetup: onPlanMeetup,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows when and where the countdown lands', (tester) async {
    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: false,
      ),
    );

    expect(find.text('Fri, Nov 20'), findsOneWidget);
    expect(find.text('7:00 PM'), findsOneWidget);
    expect(find.text('Langano Lake'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('days left'), findsOneWidget);
  });

  testWidgets('keeps the date plain when no time was planned', (tester) async {
    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 20, 10),
        openPlanOnTap: false,
        milestone: _milestoneNoPlace,
      ),
    );

    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('7:00 PM'), findsNothing);
  });

  testWidgets('counts down the day itself', (tester) async {
    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 20, 14, 40),
        openPlanOnTap: false,
      ),
    );

    expect(find.text('Today · in 4h 20m'), findsOneWidget);
    expect(find.text('today'), findsWidgets);
  });

  testWidgets('opens the plan and shares it with the crew', (tester) async {
    final chat = _FakeChatRepository();
    await tester.pumpWidget(
      _host(
        chat: chat,
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();

    expect(find.text('When'), findsOneWidget);
    expect(find.text('Fri, Nov 20 · 7:00 PM'), findsWidgets);
    expect(find.text('Where'), findsOneWidget);
    expect(find.text('Bring the guitar'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('share-countdown-plan')));
    await tester.pumpAndSettle();

    expect(chat.sent, hasLength(1));
    expect(
      chat.sent.single,
      'Fri, Nov 20 at 7:00 PM · Langano Lake. Who\'s in?',
    );
    expect(find.text('Shared the plan in the crew chat.'), findsOneWidget);
  });

  testWidgets('geocodes the place and hands it to the map picker', (
    tester,
  ) async {
    final navigation = _FakeNavigationGateway(
      spots: const [
        PlaceSuggestion(
          label: 'Langano Lake, Oromia, Ethiopia',
          name: 'Langano Lake',
          longitude: 38.72,
          latitude: 7.6,
        ),
      ],
    );
    GeoPoint? handedPoint;
    String? handedLabel;

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        navigation: navigation,
        onPlanMeetup: (point, label) {
          handedPoint = point;
          handedLabel = label;
        },
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-meetup')));
    await tester.pumpAndSettle();

    expect(navigation.queries, ['Langano Lake']);
    expect(handedPoint?.latitude, 7.6);
    expect(handedPoint?.longitude, 38.72);
    expect(handedLabel, 'Langano Lake');
    expect(find.byKey(const ValueKey('plan-meetup')), findsNothing);
  });

  testWidgets('explains when the place cannot be found', (tester) async {
    final navigation = _FakeNavigationGateway();
    var handedOff = false;

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        navigation: navigation,
        onPlanMeetup: (_, _) => handedOff = true,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan-meetup')));
    await tester.pumpAndSettle();

    expect(navigation.queries, ['Langano Lake']);
    expect(handedOff, isFalse);
    expect(
      find.text('Could not find “Langano Lake” on the map.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('plan-meetup')), findsOneWidget);
    expect(find.text('Set as group destination'), findsOneWidget);
  });

  testWidgets('hides the meetup action when there is no place', (tester) async {
    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        navigation: _FakeNavigationGateway(),
        onPlanMeetup: (_, _) {},
        milestone: _milestoneNoPlace,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('plan-meetup')), findsNothing);
    expect(find.text('Set as group destination'), findsNothing);
    expect(find.byKey(const ValueKey('share-countdown-plan')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-place')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-place')), findsNothing);
  });

  testWidgets('edits the place from the Where row', (tester) async {
    final milestones = _FakeMilestonesRepository();

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-place')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('place-field')),
    );
    expect(field.controller?.text, 'Langano Lake');

    await tester.enterText(
      find.byKey(const ValueKey('place-field')),
      'Bishoftu',
    );
    await tester.tap(find.byKey(const ValueKey('save-place')));
    await tester.pumpAndSettle();

    expect(milestones.places, [(milestoneId: 's1', place: 'Bishoftu')]);
    final inSheet = find.descendant(
      of: find.byType(MilestonePlanSheet),
      matching: find.text('Bishoftu'),
    );
    expect(inSheet, findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MilestonePlanSheet),
        matching: find.text('Langano Lake'),
      ),
      findsNothing,
    );
    expect(find.text('Place updated on the countdown.'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-place')), findsOneWidget);
  });

  testWidgets('removes the place from the Where row', (tester) async {
    final milestones = _FakeMilestonesRepository();
    final navigation = _FakeNavigationGateway();

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
        navigation: navigation,
        onPlanMeetup: (_, _) {},
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-meetup')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-place')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-place')));
    await tester.pumpAndSettle();

    expect(milestones.places, [(milestoneId: 's1', place: null)]);
    expect(find.text('Where'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MilestonePlanSheet),
        matching: find.text('Langano Lake'),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('add-place')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-meetup')), findsNothing);
    expect(find.text('Place removed from the countdown.'), findsOneWidget);
  });

  testWidgets('adds a time to a countdown that had none', (tester) async {
    final chat = _FakeChatRepository();
    final milestones = _FakeMilestonesRepository();

    await tester.pumpWidget(
      _host(
        chat: chat,
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
        milestone: _milestoneNoPlace,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();

    expect(find.text('Add time'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-when')));
    await tester.pumpAndSettle();
    expect(find.text('Start time'), findsOneWidget);
    expect(find.text('Pick a time'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pick-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('7:00 PM'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-time')));
    await tester.pumpAndSettle();

    expect(
      milestones.times,
      [(milestoneId: 's2', startsAt: DateTime(2026, 11, 21, 19))],
    );
    expect(find.text('Time added to the countdown.'), findsOneWidget);
    expect(find.text('Add time'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MilestonePlanSheet),
        matching: find.text('Sat, Nov 21 · 7:00 PM'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('share-countdown-plan')));
    await tester.pumpAndSettle();

    expect(chat.sent, ['Sat, Nov 21 at 7:00 PM. Who\'s in?']);
  });

  testWidgets('removes the time from the When row', (tester) async {
    final milestones = _FakeMilestonesRepository();

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-when')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-time')));
    await tester.pumpAndSettle();

    expect(milestones.times, [(milestoneId: 's1', startsAt: null)]);
    expect(find.text('Add time'), findsOneWidget);
    expect(find.text('Time removed from the countdown.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MilestonePlanSheet),
        matching: find.text('Fri, Nov 20'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fits the time editor on a phone-width sheet', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: _FakeMilestonesRepository(),
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-when')));
    await tester.pumpAndSettle();

    expect(find.text('Start time'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove time'), findsOneWidget);
    expect(find.text('Save time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits the place editor on a phone-width sheet', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: _FakeMilestonesRepository(),
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-place')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('place-field')), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove place'), findsOneWidget);
    expect(find.text('Save place'), findsOneWidget);
  });

  testWidgets('adds a place to an existing countdown', (tester) async {
    final milestones = _FakeMilestonesRepository();
    final navigation = _FakeNavigationGateway(
      spots: const [
        PlaceSuggestion(
          label: 'Bole Medhanealem, Addis Ababa',
          name: 'Bole Medhanealem',
          longitude: 38.78,
          latitude: 8.99,
        ),
      ],
    );
    var handedOff = false;

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
        navigation: navigation,
        onPlanMeetup: (_, _) => handedOff = true,
        milestone: _milestoneNoPlace,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-place')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('place-field')),
      '  Bole Medhanealem  ',
    );
    await tester.tap(find.byKey(const ValueKey('save-place')));
    await tester.pumpAndSettle();

    expect(milestones.places, [(milestoneId: 's2', place: 'Bole Medhanealem')]);
    expect(find.text('Where'), findsOneWidget);
    expect(find.text('Bole Medhanealem'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-place')), findsNothing);
    expect(find.byKey(const ValueKey('plan-meetup')), findsOneWidget);
    expect(find.text('Place added to the countdown.'), findsOneWidget);

    // The meetup action uses the place that was just saved.
    await tester.tap(find.byKey(const ValueKey('plan-meetup')));
    await tester.pumpAndSettle();

    expect(navigation.queries, ['Bole Medhanealem']);
    expect(handedOff, isTrue);
  });

  testWidgets('shares the place it just added', (tester) async {
    final chat = _FakeChatRepository();
    final milestones = _FakeMilestonesRepository();

    await tester.pumpWidget(
      _host(
        chat: chat,
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
        milestone: _milestoneNoPlace,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-place')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('place-field')),
      'Bole Medhanealem',
    );
    await tester.tap(find.byKey(const ValueKey('save-place')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('share-countdown-plan')));
    await tester.pumpAndSettle();

    expect(chat.sent, ['Sat, Nov 21 · Bole Medhanealem. Who\'s in?']);
  });

  testWidgets('keeps the place form open when saving fails', (tester) async {
    const failure = MilestonesFailure(
      'Could not save the place. Check your connection and try again.',
    );
    final milestones = _FakeMilestonesRepository(failure: failure);

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
        milestone: _milestoneNoPlace,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-place')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('place-field')),
      'Bole Medhanealem',
    );
    await tester.tap(find.byKey(const ValueKey('save-place')));
    await tester.pumpAndSettle();

    expect(find.text(failure.message), findsOneWidget);
    expect(find.byKey(const ValueKey('place-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-place')), findsNothing);
    expect(milestones.places, isEmpty);
  });

  testWidgets('asks for a place before saving an empty field', (tester) async {
    final milestones = _FakeMilestonesRepository();

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
        milestone: _milestoneNoPlace,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-place')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-place')));
    await tester.pumpAndSettle();

    expect(find.text('Type where you’re meeting first.'), findsOneWidget);
    expect(milestones.places, isEmpty);
    expect(find.byKey(const ValueKey('place-field')), findsOneWidget);
  });

  testWidgets('removes the countdown after confirming', (tester) async {
    final milestones = _FakeMilestonesRepository();

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    final deleteButton = find.byKey(const ValueKey('delete-countdown'));
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete this countdown?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(milestones.deleted, ['s1']);
    expect(find.byType(MilestonePlanSheet), findsNothing);
    expect(find.text('Countdown removed.'), findsOneWidget);
  });

  testWidgets('keeps the countdown when the delete is dismissed', (
    tester,
  ) async {
    final milestones = _FakeMilestonesRepository();

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    final deleteButton = find.byKey(const ValueKey('delete-countdown'));
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Keep it'));
    await tester.pumpAndSettle();

    expect(milestones.deleted, isEmpty);
    expect(find.byType(MilestonePlanSheet), findsOneWidget);
  });

  testWidgets('only offers delete to the member who added it', (tester) async {
    final fromSomeoneElse = SharedMilestone(
      id: 's3',
      title: 'Game night',
      date: DateTime(2026, 11, 21),
      kind: MilestoneKind.goal,
      createdBy: 'u2',
    );

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: _FakeMilestonesRepository(),
        milestone: fromSomeoneElse,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete-countdown')), findsNothing);
  });

  testWidgets('keeps the sheet open when deleting fails', (tester) async {
    const failure = MilestonesFailure(
      'Only the member who added this countdown can remove it.',
    );
    final milestones = _FakeMilestonesRepository(failure: failure);

    await tester.pumpWidget(
      _host(
        chat: _FakeChatRepository(),
        now: DateTime(2026, 11, 15, 10),
        openPlanOnTap: true,
        milestones: milestones,
      ),
    );

    await tester.tap(find.byType(CountdownCard));
    await tester.pumpAndSettle();
    final deleteButton = find.byKey(const ValueKey('delete-countdown'));
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text(failure.message), findsOneWidget);
    expect(find.byType(MilestonePlanSheet), findsOneWidget);
    expect(milestones.deleted, isEmpty);
  });
}
