import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../circle/domain/user_profile.dart';
import '../application/memories_providers.dart';
import '../domain/memories_failure.dart';
import '../domain/memory_post.dart';
import 'widgets/memory_photo_view.dart';
import 'widgets/memory_photo_viewer.dart';

/// One memory in full: the photo, who saved it, and the caption.
///
/// The author can delete it from here. The database already limits deletes to
/// the author; hiding the action for everyone else keeps the UI honest.
class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.memory,
    this.author,
    this.now,
  });

  final String circleId;
  final String currentUserId;
  final MemoryPost memory;
  final UserProfile? author;

  /// Fixed clock for tests; defaults to now.
  final DateTime? now;

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  bool _deleting = false;

  bool get _canDelete => widget.memory.authorId == widget.currentUserId;

  Future<void> _confirmDelete() async {
    if (_deleting) return;
    final memory = widget.memory;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this memory?'),
        content: Text(
          memory.photoPath != null
              ? 'It disappears for everyone in the circle, and the photo is '
                    'deleted too.'
              : 'It disappears for everyone in the circle. This cannot be '
                    'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _deleting = true);
    try {
      await ref
          .read(memoriesRepositoryProvider(widget.circleId))
          .deleteMemory(memory.id, photoPath: memory.photoPath);
      ref.invalidate(recentMemoriesProvider(widget.circleId));
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Memory deleted.')));
    } on MemoriesFailure catch (failure) {
      if (!mounted) return;
      setState(() => _deleting = false);
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memory = widget.memory;
    final author = widget.author;
    final now = widget.now ?? DateTime.now();
    final photoPath = memory.photoPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
          if (_canDelete)
            _deleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'Delete memory',
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          if (photoPath != null) ...[
            Stack(
              children: [
                MemoryPhotoView(
                  path: photoPath,
                  width: double.infinity,
                  height: 260,
                  borderRadius: AppRadius.tile,
                  onTap: () => showMemoryPhotoViewer(
                    context,
                    path: photoPath,
                    label:
                        '${author?.firstName ?? 'Someone'} · '
                        '${timeAgo(memory.createdAt, now: now)}',
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.open_in_full_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _AuthorRow(memory: memory, author: author, now: now),
          if (memory.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              memory.text,
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (memory.placeLabel != null || memory.voiceNoteSeconds != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (memory.placeLabel != null)
                  _MetaChip(
                    icon: Icons.place_rounded,
                    text: memory.placeLabel!,
                  ),
                if (memory.voiceNoteSeconds != null)
                  _MetaChip(
                    icon: Icons.graphic_eq_rounded,
                    text: formatVoiceNote(memory.voiceNoteSeconds!),
                  ),
              ],
            ),
          ],
          if (memory.reactions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in memory.reactions.entries)
                  _ReactionChip(emoji: entry.key, count: entry.value),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.memory,
    required this.author,
    required this.now,
  });

  final MemoryPost memory;
  final UserProfile? author;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatarColor = Color(author?.avatarColor ?? 0xFF8A5A3B);
    final onAvatar =
        ThemeData.estimateBrightnessForColor(avatarColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: avatarColor,
          child: Text(
            author?.initials ?? '?',
            style: TextStyle(
              color: onAvatar,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author?.displayName ?? 'Someone',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 1),
              Text(
                timeAgo(memory.createdAt, now: now),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '${memory.mood.emoji} ${memory.mood.label}',
            style: theme.textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$emoji $count',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
