import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../circle/domain/user_profile.dart';
import '../application/memories_providers.dart';
import '../domain/memory_post.dart';
import 'memory_detail_screen.dart';
import 'memory_mood_colors.dart';
import 'widgets/memory_composer_sheet.dart';
import 'widgets/memory_photo_view.dart';

/// Every memory in the circle, newest first, as a photo-first grid.
class MemoriesGalleryScreen extends ConsumerWidget {
  const MemoriesGalleryScreen({
    super.key,
    required this.circleId,
    required this.currentUserId,
    this.authors = const {},
    this.now,
  });

  final String circleId;
  final String currentUserId;

  /// Profiles keyed by user id, used for each tile's byline.
  final Map<String, UserProfile> authors;

  /// Fixed clock for tests; defaults to now.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(recentMemoriesProvider(circleId));
    final clock = now ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
        actions: [
          IconButton(
            tooltip: 'New memory',
            onPressed: () => showMemoryComposer(
              context,
              circleId: circleId,
              authorId: currentUserId,
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: memories.when(
        data: (items) => items.isEmpty
            ? _EmptyGallery(
                onAdd: () => showMemoryComposer(
                  context,
                  circleId: circleId,
                  authorId: currentUserId,
                ),
              )
            : _MemoryGrid(
                memories: items,
                authors: authors,
                now: clock,
                onOpen: (memory) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MemoryDetailScreen(
                      circleId: circleId,
                      currentUserId: currentUserId,
                      memory: memory,
                      author: authors[memory.authorId],
                      now: clock,
                    ),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _GalleryError(
          onRetry: () => ref.invalidate(recentMemoriesProvider(circleId)),
        ),
      ),
    );
  }
}

class _MemoryGrid extends StatelessWidget {
  const _MemoryGrid({
    required this.memories,
    required this.authors,
    required this.now,
    required this.onOpen,
  });

  final List<MemoryPost> memories;
  final Map<String, UserProfile> authors;
  final DateTime now;
  final ValueChanged<MemoryPost> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    '${memories.length} '
                    '${memories.length == 1 ? 'moment' : 'moments'}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Newest first',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.8,
                ),
                itemCount: memories.length,
                itemBuilder: (context, index) {
                  final memory = memories[index];
                  return _MemoryTile(
                    memory: memory,
                    author: authors[memory.authorId],
                    now: now,
                    onTap: () => onOpen(memory),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({
    required this.memory,
    required this.author,
    required this.now,
    required this.onTap,
  });

  final MemoryPost memory;
  final UserProfile? author;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoPath = memory.photoPath;
    final radius = BorderRadius.circular(AppRadius.tile);

    return Semantics(
      button: true,
      label:
          'Memory from ${author?.firstName ?? 'someone'}, '
          '${timeAgo(memory.createdAt, now: now)}',
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photoPath != null)
                  MemoryPhotoView(
                    path: photoPath,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  )
                else
                  _MoodBackdrop(mood: memory.mood),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xA6000000)],
                      stops: [0.42, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      memory.mood.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memory.text.isNotEmpty) ...[
                        Text(
                          memory.text,
                          maxLines: photoPath != null ? 2 : 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        '${author?.firstName ?? 'Someone'} · '
                        '${timeAgo(memory.createdAt, now: now)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodBackdrop extends StatelessWidget {
  const _MoodBackdrop({required this.mood});

  final MemoryMood mood;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: mood.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: const Alignment(0.55, -0.35),
        child: Text(
          mood.emoji,
          style: TextStyle(
            fontSize: 52,
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 28,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No memories yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The little moments you save will gather here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Save a memory'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryError extends StatelessWidget {
  const _GalleryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 32,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load your memories.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
