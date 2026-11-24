import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:pathfinders/features/chat/application/chat_providers.dart';
import 'package:pathfinders/features/chat/domain/chat_message.dart';
import 'package:pathfinders/features/chat/domain/chat_poll.dart';
import 'package:pathfinders/features/chat/domain/chat_repository.dart';
import 'package:pathfinders/features/chat/presentation/chat_tab.dart';
import 'package:pathfinders/features/chat/presentation/widgets/poll_composer_sheet.dart';
import 'package:pathfinders/features/navigation/application/navigation_providers.dart';
import 'package:pathfinders/features/navigation/domain/navigation_destination.dart'
    as nav;
import 'package:pathfinders/features/navigation/domain/navigation_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _poll = ChatMessage(
  id: 'p1',
  senderId: 'alex',
  senderName: 'Alex Doe',
  kind: ChatMessageKind.poll,
  text: 'Where should we go tonight?',
  poll: const ChatPoll(
    options: [
      ChatPollOption(
        id: 'o1',
        position: 0,
        label: 'Bole',
        voterIds: ['alex', 'me'],
      ),
      ChatPollOption(
        id: 'o2',
        position: 1,
        label: 'Entoto',
        latitude: 9.08,
        longitude: 38.77,
        placeLabel: 'Entoto Park',
        voterIds: ['alex'],
      ),
    ],
  ),
  createdAt: DateTime.now(),
);

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this.messages);

  final List<ChatMessage> messages;
  final votes = <({String messageId, String optionId})>[];

  @override
  void forceRefresh() {}

  @override
  Stream<List<ChatMessage>> watchMessages() => Stream.value(messages);

  @override
  Future<void> sendText({
    required String senderId,
    required String text,
    ChatMessage? replyTo,
    List<String> mentionedUserIds = const [],
    ChatSender? localEcho,
  }) async {}

  @override
  Future<void> shareLocation({
    required String senderId,
    required double latitude,
    required double longitude,
    String? placeLabel,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  }) async {}

  @override
  Future<void> sendGif({
    required String senderId,
    required String url,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  }) async {}

  @override
  Future<void> createPoll({
    required String senderId,
    required String question,
    required List<ChatPollDraftOption> options,
    ChatMessage? replyTo,
    ChatSender? localEcho,
  }) async {}

  @override
  Future<void> castVote({
    required String messageId,
    required String optionId,
  }) async {
    votes.add((messageId: messageId, optionId: optionId));
  }

  @override
  Future<void> editText({
    required String messageId,
    required String text,
    List<String> mentionedUserIds = const [],
  }) async {}

  @override
  Future<void> deleteMessage(String messageId) async {}
}

class _FakeNavigationRepository implements NavigationRepository {
  final destinations =
      <({String label, double latitude, double longitude, String setBy})>[];

  @override
  Future<void> setDestination({
    required String label,
    required double latitude,
    required double longitude,
    required String setBy,
  }) async {
    destinations.add((
      label: label,
      latitude: latitude,
      longitude: longitude,
      setBy: setBy,
    ));
  }

  @override
  Future<void> clearDestination() async {}

  @override
  Stream<nav.NavigationDestination?> watchDestination() =>
      Stream<nav.NavigationDestination?>.value(null);
}

Finder _field(String hint) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == hint,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a poll shows its counts and votes on tap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = _FakeChatRepository([_poll]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          chatRepositoryProvider('c1').overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChatTab(
              circleId: 'c1',
              currentUserId: 'me',
              members: const [],
              active: false,
              onShowLocation: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // let the message stream deliver

    expect(find.text('Where should we go tonight?'), findsOneWidget);
    expect(find.text('Bole'), findsOneWidget);
    expect(find.text('Entoto'), findsOneWidget);
    expect(find.text('Entoto Park'), findsOneWidget);
    expect(find.text('3 votes'), findsOneWidget);

    await tester.tap(find.text('Entoto'));
    await tester.pump();

    expect(repository.votes, [(messageId: 'p1', optionId: 'o2')]);
    // The leader (Bole) has no place pinned, so there is nothing to apply.
    expect(find.text('Make this the destination'), findsNothing);
  });

  testWidgets('the leading place becomes the destination', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final chat = _FakeChatRepository([
      ChatMessage(
        id: 'p2',
        senderId: 'alex',
        senderName: 'Alex Doe',
        kind: ChatMessageKind.poll,
        text: 'Where should we go tonight?',
        poll: const ChatPoll(
          options: [
            ChatPollOption(
              id: 'o1',
              position: 0,
              label: 'Bole',
              voterIds: ['me'],
            ),
            ChatPollOption(
              id: 'o2',
              position: 1,
              label: 'Entoto',
              latitude: 9.08,
              longitude: 38.77,
              placeLabel: 'Entoto Park',
              voterIds: ['alex', 'sam'],
            ),
          ],
        ),
        createdAt: DateTime.now(),
      ),
    ]);
    final navigation = _FakeNavigationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          chatRepositoryProvider('c1').overrideWithValue(chat),
          navigationRepositoryProvider('c1').overrideWithValue(navigation),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChatTab(
              circleId: 'c1',
              currentUserId: 'me',
              members: const [],
              active: false,
              onShowLocation: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Make this the destination'), findsOneWidget);

    await tester.tap(find.text('Make this the destination'));
    await tester.pump();
    await tester.pump();

    expect(navigation.destinations, [
      (label: 'Entoto Park', latitude: 9.08, longitude: 38.77, setBy: 'me'),
    ]);
    expect(find.text('Everyone is heading to Entoto Park.'), findsOneWidget);
  });

  testWidgets('the composer starts a vote only when it is complete', (
    tester,
  ) async {
    PollComposerResult? result;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showPollComposerSheet(context, userId: 'me');
                  },
                  child: const Text('Open vote'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open vote'));
    await tester.pumpAndSettle();

    final startVote = find.widgetWithText(FilledButton, 'Start vote');
    expect(tester.widget<FilledButton>(startVote).onPressed, isNull);

    await tester.enterText(
      _field('Where should we go tonight?'),
      'Where tonight?',
    );
    await tester.enterText(_field('Option 1'), 'Bole');
    await tester.enterText(_field('Option 2'), 'Entoto');
    await tester.pump();

    expect(tester.widget<FilledButton>(startVote).onPressed, isNotNull);

    await tester.ensureVisible(startVote);
    await tester.tap(startVote);
    await tester.pumpAndSettle();

    expect(result?.question, 'Where tonight?');
    expect(result?.options.map((option) => option.label).toList(), [
      'Bole',
      'Entoto',
    ]);
  });
}
