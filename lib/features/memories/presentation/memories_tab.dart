import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../core/utils/time_format.dart';
import '../../circle/domain/user_profile.dart';
import '../../milestones/application/milestones_providers.dart';
import '../../milestones/domain/shared_milestone.dart';
import '../../milestones/presentation/widgets/countdown_card.dart';
import '../../milestones/presentation/widgets/milestone_composer_sheet.dart';
import '../application/memories_providers.dart';
import '../domain/memory_post.dart';
import 'memory_detail_screen.dart';
import 'memory_mood_colors.dart';
import 'widgets/memory_composer_sheet.dart';
import 'widgets/memory_photo_view.dart';

/// The memories tab: upcoming milestones, the circle's photo feed and the
/// button that adds the next moment.
class MemoriesTab extends ConsumerStatefulWidget {
  const MemoriesTab({
    super.key,
    required this.circleId,
    required this.currentUserId,
    this.circleName,
    this.authors = const {},
    this.now,
  });

  final String circleId;
  final String currentUserId;
  final String? circleName;

  /// Profiles keyed by user id, used for each tile's byline.
  final Map<String, UserProfile> authors;

  /// Fixed clock for tests; defaults to now.
  final DateTime? now;

  @override
  ConsumerState<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends ConsumerState<MemoriesTab> {
  /// Null means everyone; otherwise only this author is shown.
  String? _authorFilter;

  /// Tapping the selected author again clears the filter.
  void _selectAuthor(String? authorId) {
    setState(() {
      _authorFilter = _authorFilter == authorId ? null : authorId;
    });
  }

  void _addMemory() {
    showMemoryComposer(
      context,
      circleId: widget.circleId,
      authorId: widget.currentUserId,
    );
  }

  void _addMilestone() {
    showMilestoneComposer(
      context,
      circleId: widget.circleId,
      createdBy: widget.currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final memories = ref.watch(recentMemoriesProvider(widget.circleId));
    final milestones =
        ref.watch(milestonesProvider(widget.circleId)).value ??
        const <SharedMilestone>[];
    final clock = widget.now ?? DateTime.now();
    final upcoming =
        [
          for (final milestone in milestones)
            if (milestone.daysFrom(clock) >= 0) milestone,
        ]..sort((a, b) => a.date.compareTo(b.date));

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          memories.when(
            data: (items) => _Gallery(
              items: items,
              circleName: widget.circleName,
              authors: widget.authors,
              now: clock,
              authorFilter: _authorFilter,
              onSelectAuthor: _selectAuthor,
              milestones: upcoming,
              onAddMilestone: _addMilestone,
              onAddMemory: _addMemory,
              onOpen: (memory) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MemoryDetailScreen(
                    circleId: widget.circleId,
                    currentUserId: widget.currentUserId,
                    memory: memory,
                    author: widget.authors[memory.authorId],
                    now: clock,
                  ),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _GalleryError(
              onRetry: () =>
                  ref.invalidate(recentMemoriesProvider(widget.circleId)),
            ),
          ),
          Positioned(
            right: AppSpacing.xl,
            bottom: AppSpacing.xl,
            child: FloatingActionButton.extended(
              key: const ValueKey('new-memory-fab'),
              onPressed: _addMemory,
              icon: const Icon(Icons.add_a_photo_rounded, size: 20),
              label: const Text('New memory'),
              shape: const StadiumBorder(),
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.items,
    required this.circleName,
    required this.authors,
    required this.now,
    required this.authorFilter,
    required this.onSelectAuthor,
    required this.milestones,
    required this.onAddMilestone,
    required this.onAddMemory,
    required this.onOpen,
  });

  final List<MemoryPost> items;
  final String? circleName;
  final Map<String, UserProfile> authors;
  final DateTime now;
  final String? authorFilter;
  final ValueChanged<String?> onSelectAuthor;
  final List<SharedMilestone> milestones;
  final VoidCallback onAddMilestone;
  final VoidCallback onAddMemory;
  final ValueChanged<MemoryPost> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 700 ? 3 : 2;

    final authorIds = <String>[];
    for (final memory in items) {
      if (!authorIds.contains(memory.authorId)) {
        authorIds.add(memory.authorId);
      }
    }
    final selected = authorFilter != null && authorIds.contains(authorFilter)
        ? authorFilter
        : null;
    final visible = selected == null
        ? items
        : [
            for (final memory in items)
              if (memory.authorId == selected) memory,
          ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Memories',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        circleName == null
                            ? 'The little moments you keep together'
                            : 'Little moments with $circleName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.photo_library_rounded,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _MilestoneStrip(
            milestones: milestones,
            now: now,
            onAdd: onAddMilestone,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('Moments', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${visible.length} '
                  '${visible.length == 1 ? 'memory' : 'memories'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyGallery(onAdd: onAddMemory),
          )
        else ...[
          SliverToBoxAdapter(
            child: _AuthorFilter(
              authorIds: authorIds,
              authors: authors,
              selectedAuthorId: selected,
              onSelect: onSelectAuthor,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              104,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final memory = visible[index];
                  return _MemoryTile(
                    memory: memory,
                    author: authors[memory.authorId],
                    now: now,
                    onTap: () => onOpen(memory),
                  );
                },
                childCount: visible.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MilestoneStrip extends StatelessWidget {
  const _MilestoneStrip({
    required this.milestones,
    required this.now,
    required this.onAdd,
  });

  final List<SharedMilestone> milestones;
  final DateTime now;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Text(
                'Next up',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Countdown'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: milestones.isEmpty ? 1 : milestones.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              if (milestones.isEmpty) {
                return _EmptyMilestoneCard(onTap: onAdd);
              }
              if (index == milestones.length) {
                return _AddMilestoneCard(onTap: onAdd);
              }
              return SizedBox(
                width: 292,
                child: CountdownCard(
                  milestone: milestones[index],
                  now: now,
                  onTap: onAdd,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyMilestoneCard extends StatelessWidget {
  const _EmptyMilestoneCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 292,
      child: BentoCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: onTap,
        semanticLabel: 'Add your first countdown.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const Spacer(),
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Nothing on the horizon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              'Add a countdown for the next thing you all care about.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMilestoneCard extends StatelessWidget {
  const _AddMilestoneCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);
    return SizedBox(
      width: 132,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Add countdown',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _AuthorFilter extends StatelessWidget {
  const _AuthorFilter({
    required this.authorIds,
    required this.authors,
    required this.selectedAuthorId,
    required this.onSelect,
  });

  final List<String> authorIds;
  final Map<String, UserProfile> authors;
  final String? selectedAuthorId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          _AuthorFilterChip(
            label: 'Everyone',
            selected: selectedAuthorId == null,
            onTap: () => onSelect(null),
          ),
          for (final id in authorIds) ...[
            const SizedBox(width: AppSpacing.sm),
            _AuthorFilterChip(
              label: authors[id]?.firstName ?? 'Someone',
              profile: authors[id],
              selected: selectedAuthorId == id,
              onTap: () => onSelect(id),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthorFilterChip extends StatelessWidget {
  const _AuthorFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.profile,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.pill);
    final avatar = profile;
    final avatarColor = avatar == null ? null : Color(avatar.avatarColor);
    final onAvatar = avatarColor == null
        ? null
        : ThemeData.estimateBrightnessForColor(avatarColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Semantics(
      button: true,
      selected: selected,
      label: profile == null
          ? 'Show all memories'
          : 'Show memories from $label',
      child: Material(
        color: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (avatar != null) ...[
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      avatar.initials,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: onAvatar,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        110,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
