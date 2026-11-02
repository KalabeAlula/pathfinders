import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/circle/domain/user_profile.dart';
import 'package:pathfinders/features/memories/application/memories_providers.dart';
import 'package:pathfinders/features/memories/domain/memories_failure.dart';
import 'package:pathfinders/features/memories/domain/memories_repository.dart';
import 'package:pathfinders/features/memories/domain/memory_photo.dart';
import 'package:pathfinders/features/memories/domain/memory_post.dart';
import 'package:pathfinders/features/memories/presentation/memory_detail_screen.dart';

const _alex = UserProfile(
  id: 'alex',
  displayName: 'Alex Rivera',
  avatarColor: 0xFF8A5A3B,
);

MemoryPost _memory({String authorId = 'alex'}) => MemoryPost(
  id: 'm1',
  authorId: authorId,
  text: 'Golden hour on Entoto',
  mood: MemoryMood.joyful,
  createdAt: DateTime(2026, 11, 2, 9),
  placeLabel: 'Entoto Park',
);

class _FakeMemoriesRepository implements MemoriesRepository {
  _FakeMemoriesRepository({this.deleteError});

  final MemoriesFailure? deleteError;
  String? deletedId;
  String? deletedPhotoPath;

  @override
  Stream<List<MemoryPost>> watchMemories() => const Stream.empty();

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
  Future<void> deleteMemory(String memoryId, {String? photoPath}) async {
    final error = deleteError;
    if (error != null) throw error;
    deletedId = memoryId;
    deletedPhotoPath = photoPath;
  }
}

Widget _host({
  required _FakeMemoriesRepository repository,
  String currentUserId = 'alex',
  String memoryAuthorId = 'alex',
}) {
  final memory = _memory(authorId: memoryAuthorId);
  return ProviderScope(
    overrides: [memoriesRepositoryProvider('c1').overrideWithValue(repository)],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MemoryDetailScreen(
                    circleId: 'c1',
                    currentUserId: currentUserId,
                    memory: memory,
                    author: _alex,
                    now: DateTime(2026, 11, 2, 10),
                  ),
                ),
              ),
              child: const Text('open memory'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open memory'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the photo-less memory details', (tester) async {
    final repository = _FakeMemoriesRepository();
    await tester.pumpWidget(_host(repository: repository));
    await _open(tester);

    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('Golden hour on Entoto'), findsOneWidget);
    expect(find.text('Entoto Park'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('1h ago'), findsOneWidget);
    expect(find.text('✨ Joyful'), findsOneWidget);
    expect(find.byTooltip('Delete memory'), findsOneWidget);
  });

  testWidgets('hides delete for another member\'s memory', (tester) async {
    final repository = _FakeMemoriesRepository();
    await tester.pumpWidget(
      _host(
        repository: repository,
        currentUserId: 'sam',
        memoryAuthorId: 'alex',
      ),
    );
    await _open(tester);

    expect(find.text('Golden hour on Entoto'), findsOneWidget);
    expect(find.byTooltip('Delete memory'), findsNothing);
  });

  testWidgets('keeps the memory when deletion is cancelled', (tester) async {
    final repository = _FakeMemoriesRepository();
    await tester.pumpWidget(_host(repository: repository));
    await _open(tester);

    await tester.tap(find.byTooltip('Delete memory'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this memory?'), findsOneWidget);

    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();

    expect(repository.deletedId, isNull);
    expect(find.text('Golden hour on Entoto'), findsOneWidget);
  });

  testWidgets('deletes on confirm and returns to the feed', (tester) async {
    final repository = _FakeMemoriesRepository();
    await tester.pumpWidget(_host(repository: repository));
    await _open(tester);

    await tester.tap(find.byTooltip('Delete memory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedId, 'm1');
    expect(find.text('Golden hour on Entoto'), findsNothing);
    expect(find.text('Memory deleted.'), findsOneWidget);
  });

  testWidgets('stays open and reports a failed delete', (tester) async {
    final repository = _FakeMemoriesRepository(
      deleteError: const MemoriesFailure('Could not delete that memory.'),
    );
    await tester.pumpWidget(_host(repository: repository));
    await _open(tester);

    await tester.tap(find.byTooltip('Delete memory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedId, isNull);
    expect(find.text('Golden hour on Entoto'), findsOneWidget);
    expect(find.text('Could not delete that memory.'), findsOneWidget);
  });
}
