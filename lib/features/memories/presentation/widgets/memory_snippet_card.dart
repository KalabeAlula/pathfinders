import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/bento_card.dart';
import '../../../../core/utils/time_format.dart';
import '../../../circle/domain/user_profile.dart';
import '../../domain/memory_post.dart';

class MemorySnippetCard extends StatelessWidget {
  const MemorySnippetCard({
    super.key,
    required this.memory,
    required this.author,
    required this.now,
    this.onTap,
  });

  final MemoryPost memory;
  final UserProfile? author;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BentoCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      semanticLabel: 'Latest memory. Add another.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: memory.mood.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(
              memory.mood.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: author?.firstName ?? 'Someone',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            TextSpan(
                              text: '  ·  ${memory.mood.label}',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo(memory.createdAt, now: now),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  memory.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (memory.placeLabel != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            memory.placeLabel!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    for (final entry in memory.reactions.entries.take(2))
                      _ReactionChip(emoji: entry.key, count: entry.value),
                    if (memory.voiceNoteSeconds != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.graphic_eq_rounded,
                              size: 11,
                              color: scheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              formatVoiceNote(memory.voiceNoteSeconds!),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: scheme.onSecondaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    if (onTap != null)
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.emoji, required this.count});

  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$emoji $count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
      ),
    );
  }
}

extension on MemoryMood {
  List<Color> get colors => switch (this) {
        MemoryMood.cozy => const [Color(0xFFC7974C), Color(0xFF8A5A3B)],
        MemoryMood.joyful => const [Color(0xFFE0A487), Color(0xFFB86B4F)],
        MemoryMood.calm => const [Color(0xFF9DB4B7), Color(0xFF687F7C)],
        MemoryMood.silly => const [Color(0xFFD0A75F), Color(0xFF7C8C6B)],
        MemoryMood.proud => const [Color(0xFF7C8C6B), Color(0xFFB86B4F)],
      };
}
