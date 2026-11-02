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
  bool _reacting = false;
  late Map<String, int> _reactions;
  late String? _myReaction;

  bool get _canDelete => widget.memory.authorId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _reactions = Map.of(widget.memory.reactions);
    _myReaction = widget.memory.myReaction;
  }

  Future<void> _toggleReaction(String emoji) async {
    if (_reacting) return;
    final memory = widget.memory;
    final previousReaction = _myReaction;
    final previousCounts = Map<String, int>.of(_reactions);
    final removing = previousReaction == emoji;

    void adjust(String? target, int delta) {
      if (target == null) return;
      final next = (_reactions[target] ?? 0) + delta;
      if (next <= 0) {
        _reactions.remove(target);
      } else {
        _reactions[target] = next;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _reacting = true;
      if (removing) {
        adjust(emoji, -1);
        _myReaction = null;
      } else {
        adjust(previousReaction, -1);
        adjust(emoji, 1);
        _myReaction = emoji;
      }
    });

    try {
      final repository = ref.read(memoriesRepositoryProvider(widget.circleId));
      if (removing) {
        await repository.clearReaction(memory.id);
      } else {
        await repository.setReaction(memoryId: memory.id, emoji: emoji);
      }
      if (!mounted) return;
      ref.invalidate(recentMemoriesProvider(widget.circleId));
      setState(() => _reacting = false);
    } on MemoriesFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _reactions = previousCounts;
        _myReaction = previousReaction;
        _reacting = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

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
    final scheme = theme.colorScheme;
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'How did this moment land?',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReactionBar(
            counts: _reactions,
            myReaction: _myReaction,
            busy: _reacting,
            onTap: _toggleReaction,
          ),
          if (_myReaction == null) ...[
            const SizedBox(height: 6),
            Text(
              _reactions.isEmpty
                  ? 'Be the first to react to this moment.'
                  : 'Add yours — one reaction per person.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
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

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.counts,
    required this.myReaction,
    required this.busy,
    required this.onTap,
  });

  final Map<String, int> counts;
  final String? myReaction;
  final bool busy;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final emoji in memoryReactionEmojis)
          _ReactionButton(
            emoji: emoji,
            count: counts[emoji] ?? 0,
            selected: myReaction == emoji,
            onTap: busy ? null : () => onTap(emoji),
          ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.pill);

    return Semantics(
      button: true,
      selected: selected,
      label: 'React with $emoji',
      child: Material(
        color: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.45)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 17)),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
