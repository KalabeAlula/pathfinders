import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/chat/domain/chat_poll.dart';

ChatPollOption _option(
  String id,
  int position, [
  List<String> voters = const [],
]) {
  return ChatPollOption(
    id: id,
    position: position,
    label: 'Option $id',
    voterIds: voters,
  );
}

void main() {
  group('ChatPoll', () {
    test('counts every vote across options', () {
      final poll = ChatPoll(
        options: [
          _option('a', 0, ['me', 'alex']),
          _option('b', 1, ['sam']),
        ],
      );

      expect(poll.totalVotes, 3);
      expect(poll.votedOptionId('alex'), 'a');
      expect(poll.votedOptionId('sam'), 'b');
      expect(poll.votedOptionId('nobody'), isNull);
    });

    test('leader is the most-voted option, null when nobody voted', () {
      expect(
        ChatPoll(options: [_option('a', 0), _option('b', 1)]).leader,
        isNull,
      );

      final poll = ChatPoll(
        options: [
          _option('a', 0, ['me']),
          _option('b', 1, ['alex', 'sam']),
        ],
      );

      expect(poll.leader?.id, 'b');
    });

    test('leader is null on a shared lead', () {
      final poll = ChatPoll(
        options: [
          _option('a', 0, ['me']),
          _option('b', 1, ['alex']),
        ],
      );

      expect(poll.leader, isNull);
    });

    test('withVote moves the member vote and can clear it', () {
      final poll = ChatPoll(
        options: [
          _option('a', 0, ['alex']),
          _option('b', 1),
        ],
      );

      final moved = poll.withVote(userId: 'me', optionId: 'b');
      expect(moved.votedOptionId('me'), 'b');
      expect(moved.votedOptionId('alex'), 'a');

      final changed = moved.withVote(userId: 'me', optionId: 'a');
      expect(changed.votedOptionId('me'), 'a');
      expect(changed.options.first.voterIds, ['alex', 'me']);

      final cleared = changed.withVote(userId: 'me', optionId: null);
      expect(cleared.votedOptionId('me'), isNull);
      expect(cleared.options.first.voterIds, ['alex']);
    });
  });
}
