import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/memories/application/memories_providers.dart';
import 'package:pathfinders/features/memories/domain/memories_failure.dart';
import 'package:pathfinders/features/memories/domain/memories_repository.dart';
import 'package:pathfinders/features/memories/domain/memory_photo.dart';
import 'package:pathfinders/features/memories/domain/memory_post.dart';
import 'package:pathfinders/features/memories/presentation/memories_tab.dart';
import 'package:pathfinders/features/milestones/application/milestones_providers.dart';
import 'package:pathfinders/features/milestones/domain/shared_milestone.dart';

const _alex = UserProfile(
  id: 'alex',
  displayName: 'Alex Rivera',
  avatarColor: 0xFF8A5A3B,
);

const _sam = UserProfile(
  id: 'sam',
  displayName: 'Sam Okafor',
  avatarColor: 0xFF7C8C6B,
);

const _nadia = UserProfile(
  id: 'nadia',
  displayName: 'Nadia Haile',
  avatarColor: 0xFFC7974C,
);

List<MemoryPost> _memories() => [
  MemoryPost(
    id: 'm1',
    authorId: 'alex',
    text: 'Golden hour on Entoto',
    mood: MemoryMood.joyful,
    createdAt: DateTime(2026, 11, 2, 9),
  ),
  MemoryPost(
    id: 'm2',
    authorId: 'sam',
    text: 'Flat white and a card game',
    mood: MemoryMood.cozy,
    createdAt: DateTime(2026, 11, 1, 18),
  ),
];

class _FakeMemoriesRepository implements MemoriesRepository {
  _FakeMemoriesRepository(this.memories, {this.error});

  final List<MemoryPost> memories;
  final Object? error;

  @override
  Stream<List<MemoryPost>> watchMemories() {
    final failure = error;
    if (failure != null) return Stream<List<MemoryPost>>.error(failure);
    return Stream.value(memories);
  }

  @override
  Future<void> addMemory({
    required String authorId,
    required String text,
    required MemoryMood mood,
    String? placeLabel,
    int? voiceNoteSeconds,
    MemoryPhotoDraft? photo,
  }) async {}

  @override
  Future<void> deleteMemory(String memoryId, {String? photoPath}) async {}

  @override
  Future<void> setReaction({
    required String memoryId,
    required String emoji,
  }) async {}

  @override
  Future<void> clearReaction(String memoryId) async {}
}

Widget _host(
  _FakeMemoriesRepository repository, {
  List<SharedMilestone> milestones = const [],
}) {
  return ProviderScope(
    overrides: [
      memoriesRepositoryProvider('c1').overrideWithValue(repository),
      milestonesProvider('c1').overrideWith(
        (_) => Stream.value(milestones),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: MemoriesTab(
          circleId: 'c1',
          currentUserId: 'alex',
          authors: const {'alex': _alex, 'sam': _sam, 'nadia': _nadia},
          now: DateTime(2026, 11, 2, 10),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('lists every memory with bylines and a count', (tester) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(_memories())));
    await tester.pumpAndSettle();

    expect(find.text('Memories'), findsOneWidget);
    expect(find.text('2 memories'), findsOneWidget);
    expect(find.text('New memory'), findsOneWidget);
    expect(find.text('Golden hour on Entoto'), findsOneWidget);
    expect(find.text('Flat white and a card game'), findsOneWidget);
    expect(find.text('Alex · 1h ago'), findsOneWidget);
    expect(find.text('Sam · 16h ago'), findsOneWidget);
  });

  testWidgets('uses a singular count for one memory', (tester) async {
    await tester.pumpWidget(
      _host(_FakeMemoriesRepository([_memories().first])),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 memory'), findsOneWidget);
  });

  testWidgets('shows filters only for authors in the feed', (tester) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(_memories())));
    await tester.pumpAndSettle();

    expect(find.text('Everyone'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Nadia'), findsNothing);
  });

  testWidgets('filters the grid by author and back to everyone', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(_memories())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sam'));
    await tester.pumpAndSettle();

    expect(find.text('1 memory'), findsOneWidget);
    expect(find.text('Flat white and a card game'), findsOneWidget);
    expect(find.text('Golden hour on Entoto'), findsNothing);

    await tester.tap(find.text('Everyone'));
    await tester.pumpAndSettle();

    expect(find.text('2 memories'), findsOneWidget);
    expect(find.text('Golden hour on Entoto'), findsOneWidget);
    expect(find.text('Flat white and a card game'), findsOneWidget);
  });

  testWidgets('tapping the selected author again shows everyone', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(_memories())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    expect(find.text('1 memory'), findsOneWidget);

    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    expect(find.text('2 memories'), findsOneWidget);
    expect(find.text('Flat white and a card game'), findsOneWidget);
  });

  testWidgets('opens the detail screen from a tile', (tester) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(_memories())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Golden hour on Entoto'));
    await tester.pumpAndSettle();

    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('✨ Joyful'), findsOneWidget);
  });

  testWidgets('offers a first memory when the feed is empty', (tester) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(const [])));
    await tester.pumpAndSettle();

    expect(find.text('No memories yet'), findsOneWidget);
    expect(find.text('Save a memory'), findsOneWidget);
    expect(find.text('Memories'), findsOneWidget);
  });

  testWidgets('invites a first countdown when the rail is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(_memories())));
    await tester.pumpAndSettle();

    expect(find.text('Nothing on the horizon'), findsOneWidget);
    expect(find.text('Plan a countdown'), findsOneWidget);
    expect(find.text('Countdown'), findsNothing);
    expect(find.text('Add countdown'), findsNothing);
  });

  testWidgets('opens the composer from the empty countdown rail', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(_memories())));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('empty-countdown-cta')));
    await tester.pumpAndSettle();

    expect(find.text('Add a countdown'), findsOneWidget);
  });

  testWidgets('drops the empty panel once a countdown exists', (tester) async {
    await tester.pumpWidget(
      _host(
        _FakeMemoriesRepository(_memories()),
        milestones: [
          SharedMilestone(
            id: 's1',
            title: 'Dooms day',
            date: DateTime(2026, 11, 16),
            kind: MilestoneKind.birthday,
            createdBy: 'alex',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dooms day'), findsOneWidget);
    expect(find.text('Countdown'), findsOneWidget);
    expect(find.text('Nothing on the horizon'), findsNothing);
    expect(find.text('Plan a countdown'), findsNothing);
  });

  testWidgets('shows an error state that can retry', (tester) async {
    await tester.pumpWidget(
      _host(
        _FakeMemoriesRepository(
          const [],
          error: const MemoriesFailure('Could not load your memories.'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load your memories.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });
}
