import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/memories/application/memories_providers.dart';
import 'package:pathfinders/features/memories/domain/memories_failure.dart';
import 'package:pathfinders/features/memories/domain/memories_repository.dart';
import 'package:pathfinders/features/memories/domain/memory_photo.dart';
import 'package:pathfinders/features/memories/domain/memory_post.dart';
import 'package:pathfinders/features/memories/presentation/memories_gallery_screen.dart';

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
}

Widget _host(_FakeMemoriesRepository repository) {
  return ProviderScope(
    overrides: [memoriesRepositoryProvider('c1').overrideWithValue(repository)],
    child: MaterialApp(
      home: MemoriesGalleryScreen(
        circleId: 'c1',
        currentUserId: 'alex',
        authors: const {'alex': _alex, 'sam': _sam},
        now: DateTime(2026, 11, 2, 10),
      ),
    ),
  );
}

void main() {
  testWidgets('lists every memory with bylines and a count', (tester) async {
    await tester.pumpWidget(_host(_FakeMemoriesRepository(_memories())));
    await tester.pumpAndSettle();

    expect(find.text('Memories'), findsOneWidget);
    expect(find.text('2 moments'), findsOneWidget);
    expect(find.text('Newest first'), findsOneWidget);
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

    expect(find.text('1 moment'), findsOneWidget);
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
