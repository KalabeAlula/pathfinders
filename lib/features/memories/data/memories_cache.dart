import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/memory_post.dart';

/// Last known memory feed for one circle.
///
/// The cache lets the feed render before the network answers, and keeps the
/// last good list visible when the first fetch fails after a restart.
class MemoriesCache {
  MemoriesCache(this._preferences, {required this.circleId});

  final SharedPreferences _preferences;
  final String circleId;

  static const maxEntries = 40;

  String get _key => 'memories.cache.$circleId';

  List<MemoryPost>? read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! List) return null;

    final memories = <MemoryPost>[];
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        memories.add(_decode(entry));
      } on Object {
        // Skip a single corrupt entry instead of losing the whole feed.
        continue;
      }
    }
    return memories;
  }

  Future<void> write(List<MemoryPost> memories) {
    final encoded = jsonEncode([
      for (final memory in memories.take(maxEntries)) _encode(memory),
    ]);
    return _preferences.setString(_key, encoded);
  }

  static Map<String, Object?> _encode(MemoryPost memory) => {
    'id': memory.id,
    'authorId': memory.authorId,
    'text': memory.text,
    'mood': memory.mood.name,
    'createdAt': memory.createdAt.toUtc().toIso8601String(),
    'placeLabel': memory.placeLabel,
    'voiceNoteSeconds': memory.voiceNoteSeconds,
    'photoPath': memory.photoPath,
    'reactions': memory.reactions,
    'myReaction': memory.myReaction,
  };

  static MemoryPost _decode(Map<String, dynamic> json) => MemoryPost(
    id: json['id'] as String,
    authorId: json['authorId'] as String,
    text: (json['text'] as String?) ?? '',
    mood: MemoryMood.values.firstWhere(
      (mood) => mood.name == json['mood'],
      orElse: () => MemoryMood.cozy,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    placeLabel: json['placeLabel'] as String?,
    voiceNoteSeconds: (json['voiceNoteSeconds'] as num?)?.toInt(),
    photoPath: json['photoPath'] as String?,
    reactions: _decodeReactions(json['reactions']),
    myReaction: json['myReaction'] as String?,
  );

  static Map<String, int> _decodeReactions(Object? raw) {
    if (raw is! Map) return const {};
    final reactions = <String, int>{};
    for (final entry in raw.entries) {
      final emoji = entry.key;
      final count = entry.value;
      if (emoji is String && count is num && count > 0) {
        reactions[emoji] = count.toInt();
      }
    }
    return reactions;
  }
}
