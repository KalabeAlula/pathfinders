import '../../circle/domain/user_profile.dart';

/// One `@Name` occurrence in a chat body.
class ChatMention {
  const ChatMention({
    required this.userId,
    required this.displayName,
    required this.start,
    required this.end,
  });

  final String userId;
  final String displayName;

  /// Index of the `@`.
  final int start;

  /// Index just past the last character of the name.
  final int end;

  String get token => '@$displayName';
}

/// A piece of a chat body, either plain text or a mention of [userId].
class ChatTextSegment {
  const ChatTextSegment({required this.text, this.userId});

  final String text;
  final String? userId;
}

/// The `@…` run the caret is in while a mention is being typed.
class ChatMentionDraft {
  const ChatMentionDraft({
    required this.start,
    required this.end,
    required this.query,
    required this.matches,
  });

  /// Index of the `@`.
  final int start;

  /// Caret position just past the typed characters.
  final int end;

  /// What was typed after the `@`, possibly empty.
  final String query;

  /// Members whose display name starts with [query], in display order.
  final List<UserProfile> matches;
}

/// Finds the member mentions in [text].
///
/// A token is `@` followed by the member's full display name, so names with
/// spaces still match. A mention must start at a word boundary and end at one,
/// which keeps `hello@ann` and `@Annabel` from tagging `Ann`. When two names
/// overlap, the longer one wins.
List<ChatMention> findMentions(String text, Iterable<UserProfile> members) {
  if (text.isEmpty) return const [];

  final folded = text.toLowerCase();
  final candidates = <ChatMention>[];

  for (final member in members) {
    final name = member.displayName.trim();
    if (name.isEmpty) continue;

    final token = '@${name.toLowerCase()}';
    var index = folded.indexOf(token);
    while (index != -1) {
      final end = index + token.length;
      if (_startsToken(text, index) && _endsToken(text, end)) {
        candidates.add(
          ChatMention(
            userId: member.id,
            displayName: name,
            start: index,
            end: end,
          ),
        );
      }
      index = folded.indexOf(token, index + 1);
    }
  }

  if (candidates.isEmpty) return const [];

  candidates.sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    return byStart != 0 ? byStart : b.end.compareTo(a.end);
  });

  final mentions = <ChatMention>[];
  var cursor = 0;
  for (final candidate in candidates) {
    if (candidate.start < cursor) continue;
    mentions.add(candidate);
    cursor = candidate.end;
  }
  return mentions;
}

/// The distinct members tagged in [text], handy for the message payload.
List<String> findMentionedUserIds(String text, Iterable<UserProfile> members) {
  final ids = <String>{};
  for (final mention in findMentions(text, members)) {
    ids.add(mention.userId);
  }
  return List<String>.unmodifiable(ids);
}

/// The mention the caret is in, or null when it is outside one.
///
/// The query may contain spaces so `@Ann Lee` keeps matching while it is
/// typed. It ends as soon as the run stops being a prefix of a member name,
/// which also hides the popover once a completed `@Name ` is followed by more
/// words.
ChatMentionDraft? findMentionDraft({
  required String text,
  required int caret,
  required Iterable<UserProfile> members,
  String? excludeUserId,
}) {
  if (caret <= 0 || caret > text.length) return null;

  final at = text.lastIndexOf('@', caret - 1);
  if (at < 0 || !_startsToken(text, at)) return null;

  final query = text.substring(at + 1, caret);
  if (query.contains('\n') || query.contains('\r')) return null;

  final folded = query.toLowerCase();
  final matches = <UserProfile>[
    for (final member in members)
      if (member.id != excludeUserId &&
          member.displayName.trim().toLowerCase().startsWith(folded))
        member,
  ];
  if (matches.isEmpty) return null;

  matches.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return ChatMentionDraft(
    start: at,
    end: caret,
    query: query,
    matches: List<UserProfile>.unmodifiable(matches),
  );
}

/// Swaps [draft] for `@Display Name ` and reports where the caret belongs.
///
/// A space the user already typed after the run is folded into the token so
/// picking a suggestion never leaves a double space behind.
({String text, int caret}) completeMention(
  String text,
  ChatMentionDraft draft,
  String displayName,
) {
  final token = '@${displayName.trim()} ';
  var end = draft.end;
  if (end < text.length && text[end] == ' ') end++;
  return (
    text: text.replaceRange(draft.start, end, token),
    caret: draft.start + token.length,
  );
}

/// Splits [text] into plain and mention pieces for styled rendering.
List<ChatTextSegment> mentionSegments(String text, List<ChatMention> mentions) {
  if (text.isEmpty) return const [];
  if (mentions.isEmpty) return [ChatTextSegment(text: text)];

  final segments = <ChatTextSegment>[];
  var cursor = 0;
  for (final mention in mentions) {
    if (mention.start > cursor) {
      segments.add(
        ChatTextSegment(text: text.substring(cursor, mention.start)),
      );
    }
    segments.add(
      ChatTextSegment(
        text: text.substring(mention.start, mention.end),
        userId: mention.userId,
      ),
    );
    cursor = mention.end;
  }
  if (cursor < text.length) {
    segments.add(ChatTextSegment(text: text.substring(cursor)));
  }
  return segments;
}

bool _startsToken(String text, int index) =>
    index == 0 || !_isWordChar(text.codeUnitAt(index - 1));

bool _endsToken(String text, int index) =>
    index == text.length || !_isWordChar(text.codeUnitAt(index));

bool _isWordChar(int rune) =>
    (rune >= 0x30 && rune <= 0x39) ||
    (rune >= 0x41 && rune <= 0x5A) ||
    (rune >= 0x61 && rune <= 0x7A) ||
    rune == 0x5F;
