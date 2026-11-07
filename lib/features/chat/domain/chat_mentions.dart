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
