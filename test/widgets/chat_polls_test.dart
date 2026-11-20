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
