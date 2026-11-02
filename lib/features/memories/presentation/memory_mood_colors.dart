import 'package:flutter/material.dart';

import '../domain/memory_post.dart';

/// The warm palette behind photo-less memories.
extension MemoryMoodColors on MemoryMood {
  List<Color> get colors => switch (this) {
    MemoryMood.cozy => const [Color(0xFFC7974C), Color(0xFF8A5A3B)],
    MemoryMood.joyful => const [Color(0xFFE0A487), Color(0xFFB86B4F)],
    MemoryMood.calm => const [Color(0xFF9DB4B7), Color(0xFF687F7C)],
    MemoryMood.silly => const [Color(0xFFD0A75F), Color(0xFF7C8C6B)],
    MemoryMood.proud => const [Color(0xFF7C8C6B), Color(0xFFB86B4F)],
  };
}
