enum MemoryMood {
  cozy(label: 'Cozy', emoji: '🍂'),
  joyful(label: 'Joyful', emoji: '✨'),
  calm(label: 'Calm', emoji: '🌤'),
  silly(label: 'Silly', emoji: '😄'),
  proud(label: 'Proud', emoji: '🌱');

  const MemoryMood({required this.label, required this.emoji});

  final String label;
  final String emoji;
}

/// The reactions a member can leave. One per person per memory.
const List<String> memoryReactionEmojis = ['🧡', '✨', '😂', '🌱'];

class MemoryPost {
  const MemoryPost({
    required this.id,
    required this.authorId,
    required this.text,
    required this.mood,
    required this.createdAt,
    this.placeLabel,
    this.voiceNoteSeconds,
    this.photoPath,
    this.reactions = const {},
    this.myReaction,
  });

  final String id;
  final String authorId;

  /// Empty when the memory is a photo with no caption.
  final String text;
  final MemoryMood mood;
  final DateTime createdAt;
  final String? placeLabel;
  final int? voiceNoteSeconds;

  /// Object path in the private `memories` bucket, signed on demand.
  final String? photoPath;

  /// Emoji to count, e.g. `{'🧡': 3}`.
  final Map<String, int> reactions;

  /// The emoji the signed-in member left, if any.
  final String? myReaction;

  int get reactionTotal =>
      reactions.values.fold(0, (total, count) => total + count);
}
