import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/features/auth/application/auth_providers.dart';
import 'package:pathfinders/features/auth/domain/auth_session.dart';
import 'package:pathfinders/features/profile/application/profile_providers.dart';
import 'package:pathfinders/features/profile/domain/profile_details.dart';
import 'package:pathfinders/features/profile/domain/profile_repository.dart';
import 'package:pathfinders/features/profile/presentation/profile_tab.dart';

class _FakeProfileRepository implements ProfileRepository {
  final changes = StreamController<ProfileDetails>.broadcast();
  final names = <String>[];
  final avatars = <String>[];

  @override
  Stream<ProfileDetails> watchProfile() => changes.stream;

  @override
  Future<void> updateDisplayName(String displayName) async {
    names.add(displayName);
  }

  @override
  Future<void> updateAvatar(String avatarId) async {
    avatars.add(avatarId);
  }
}

final _profile = ProfileDetails(
  userId: 'u1',
  displayName: 'Kaleab',
  avatarId: 'avatar_wolf',
  createdAt: DateTime(2026, 3, 14),
);

void main() {
  late _FakeProfileRepository repository;

  setUp(() {
    repository = _FakeProfileRepository();
  });

  tearDown(() async {
    await repository.changes.close();
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider('u1').overrideWithValue(repository),
          authSessionProvider.overrideWith(
            (_) => Stream.value(
              const AuthSession(userId: 'u1', email: 'kaleab@example.com'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ProfileTab(currentUserId: 'u1')),
        ),
      ),
    );
    repository.changes.add(_profile);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the identity, animal, and account details', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('Kaleab'), findsWidgets);
    expect(find.text('Simien Wolf'), findsWidgets);
    expect(find.text('kaleab@example.com'), findsOneWidget);
    expect(find.text('March 2026'), findsOneWidget);
    expect(find.text('Save name'), findsOneWidget);
    expect(find.text('Save avatar'), findsOneWidget);
  });

  testWidgets('saves the edited display name', (tester) async {
    await pumpProfile(tester);

    await tester.enterText(
      find.byKey(const ValueKey('profile-name-field')),
      '  Kaleab Tesfaye ',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('profile-name-save')));
    await tester.pump();
    await tester.pump();

    expect(repository.names, ['Kaleab Tesfaye']);
    expect(find.text('Name saved.'), findsOneWidget);
  });

  testWidgets('selecting an animal enables and runs the avatar save', (
    tester,
  ) async {
    await pumpProfile(tester);

    final saveButton = find.byKey(const ValueKey('profile-avatar-save'));
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('avatar-avatar_lion')));
    await tester.pump();

    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump();

    expect(repository.avatars, ['avatar_lion']);
    expect(find.text('Avatar updated.'), findsOneWidget);
    expect(find.text('Golden Lion'), findsWidgets);
  });
}
