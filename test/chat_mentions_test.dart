import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/chat/domain/chat_mentions.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';

const _members = [
  UserProfile(id: 'ann', displayName: 'Ann', avatarColor: 0xFF000000),
  UserProfile(id: 'ann-lee', displayName: 'Ann Lee', avatarColor: 0xFF000000),
  UserProfile(id: 'sam', displayName: 'Sam Rivera', avatarColor: 0xFF000000),
];

void main() {
  group('findMentions', () {
    test('matches a display name case-insensitively', () {
      final mentions = findMentions('hey @ann look', _members);

      expect(mentions, hasLength(1));
      expect(mentions.single.userId, 'ann');
      expect(mentions.single.start, 4);
      expect(mentions.single.end, 8);
    });

    test('matches names with spaces', () {
      final mentions = findMentions('@Sam Rivera can you drive?', _members);

      expect(mentions.single.userId, 'sam');
      expect(mentions.single.token, '@Sam Rivera');
    });

    test('prefers the longer overlapping name', () {
      final mentions = findMentions('@Ann Lee hi', _members);

      expect(mentions.single.userId, 'ann-lee');
    });

    test('ignores a name glued to more letters', () {
      expect(findMentions('@Annabel hi', _members), isEmpty);
    });

    test('ignores an @ inside a word', () {
      expect(findMentions('mail me at hello@ann', _members), isEmpty);
    });

    test('finds several mentions in order', () {
      final mentions = findMentions('@Ann and @Sam Rivera', _members);

      expect([for (final mention in mentions) mention.userId], ['ann', 'sam']);
    });

    test('needs a boundary after a shorter name', () {
      final mentions = findMentions('@Ann, meet @Ann Lee', _members);

      expect(
        [for (final mention in mentions) mention.userId],
        ['ann', 'ann-lee'],
      );
    });
  });

  group('findMentionedUserIds', () {
    test('returns each tagged member once', () {
      expect(findMentionedUserIds('@Ann ping @Ann again', _members), ['ann']);
    });

    test('returns nothing without mentions', () {
      expect(findMentionedUserIds('plain text', _members), isEmpty);
    });
  });

  group('mentionSegments', () {
    test('keeps the original text when there are no mentions', () {
      final segments = mentionSegments('plain text', const []);

      expect(segments.single.text, 'plain text');
      expect(segments.single.userId, isNull);
    });

    test('marks only the mention piece', () {
      final text = 'hey @Ann bring snacks';
      final segments = mentionSegments(text, findMentions(text, _members));

      expect(
        [for (final segment in segments) segment.text],
        ['hey ', '@Ann', ' bring snacks'],
      );
      expect(segments[1].userId, 'ann');
      expect(segments.map((segment) => segment.text).join(), text);
    });
  });

  group('findMentionDraft', () {
    test('opens on a bare @ at a word start', () {
      final draft = findMentionDraft(
        text: 'hey @',
        caret: 5,
        members: _members,
      );

      expect(draft, isNotNull);
      expect(draft!.start, 4);
      expect(draft.query, isEmpty);
      expect(
        [for (final member in draft.matches) member.id],
        ['ann', 'ann-lee', 'sam'],
      );
    });

    test('narrows the matches by name prefix', () {
      final draft = findMentionDraft(
        text: 'hey @ann l',
        caret: 10,
        members: _members,
      );

      expect([for (final member in draft!.matches) member.id], ['ann-lee']);
      expect(draft.query, 'ann l');
    });

    test('ignores an @ inside a word', () {
      expect(
        findMentionDraft(text: 'mail hello@', caret: 10, members: _members),
        isNull,
      );
    });

    test('keeps suggesting a longer name after a space', () {
      final draft = findMentionDraft(
        text: '@Ann ',
        caret: 5,
        members: _members,
      );

      expect([for (final member in draft!.matches) member.id], ['ann-lee']);
    });

    test('closes once the run stops matching a name', () {
      expect(
        findMentionDraft(text: '@Sam R thanks', caret: 12, members: _members),
        isNull,
      );
    });

    test('uses the caret, not the end of the text', () {
      final draft = findMentionDraft(
        text: '@Ann and more',
        caret: 4,
        members: _members,
      );

      expect(draft!.query, 'Ann');
      expect(
        [for (final member in draft.matches) member.id],
        ['ann', 'ann-lee'],
      );
    });

    test('skips the member writing the message', () {
      final draft = findMentionDraft(
        text: '@',
        caret: 1,
        members: _members,
        excludeUserId: 'ann',
      );

      expect(
        [for (final member in draft!.matches) member.id],
        ['ann-lee', 'sam'],
      );
    });
  });

  group('completeMention', () {
    test('replaces the typed run with the full token', () {
      const text = 'hey @ann see you';
      final draft = findMentionDraft(text: text, caret: 8, members: _members)!;
      final completed = completeMention(text, draft, 'Ann Lee');

      expect(completed.text, 'hey @Ann Lee see you');
      expect(completed.caret, 13);
    });

    test('adds the separating space when the run ends the text', () {
      const text = 'hey @ann';
      final draft = findMentionDraft(text: text, caret: 8, members: _members)!;
      final completed = completeMention(text, draft, 'Ann');

      expect(completed.text, 'hey @Ann ');
      expect(completed.caret, 9);
    });
  });
}
