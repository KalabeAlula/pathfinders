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

class MemoryPost {
  const MemoryPost({
    required this.id,
    required this.authorId,
    required this.text,
    required this.mood,
    required this.createdAt,
    this.placeLabel,
    this.voiceNoteSeconds,
    this.reactions = const {},
  });

  final String id;
  final String authorId;
  final String text;
  final MemoryMood mood;
  final DateTime createdAt;
  final String? placeLabel;
  final int? voiceNoteSeconds;

  /// Emoji to count, e.g. `{'🧡': 3}`.
  final Map<String, int> reactions;

  int get reactionTotal =>
      reactions.values.fold(0, (total, count) => total + count);
}
