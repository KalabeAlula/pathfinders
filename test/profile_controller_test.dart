import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/profile/application/profile_providers.dart';
import 'package:pathfinders/features/profile/domain/profile_details.dart';
import 'package:pathfinders/features/profile/domain/profile_failure.dart';
import 'package:pathfinders/features/profile/domain/profile_repository.dart';

class _FakeProfileRepository implements ProfileRepository {
  final changes = StreamController<ProfileDetails>.broadcast();
  final names = <String>[];
  final avatars = <String>[];
  ProfileFailure? failWith;

  @override
  Stream<ProfileDetails> watchProfile() => changes.stream;

  @override
  Future<void> updateDisplayName(String displayName) async {
    if (failWith case final failure?) throw failure;
    names.add(displayName);
  }

  @override
  Future<void> updateAvatar(String avatarId) async {
    if (failWith case final failure?) throw failure;
    avatars.add(avatarId);
  }
}

final _initial = ProfileDetails(
  userId: 'u1',
  displayName: 'Kaleab',
  avatarId: 'avatar_wolf',
  createdAt: DateTime(2026, 3, 14),
);

final controller = profileControllerProvider('u1');

void main() {
  late _FakeProfileRepository repository;
  late ProviderContainer container;

  setUp(() async {
    repository = _FakeProfileRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider('u1').overrideWithValue(repository),
      ],
    );
    container.listen(controller, (_, _) {});
    repository.changes.add(_initial);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    container.dispose();
    await repository.changes.close();
  });

  test('starts from the stored profile and follows realtime changes', () async {
    final stored = container.read(controller).value!;
    expect(stored.displayName, 'Kaleab');
    expect(stored.avatarId, 'avatar_wolf');

    repository.changes.add(stored.copyWith(displayName: 'Kaleab T.'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(controller).value?.displayName, 'Kaleab T.');
  });

  test('display name is trimmed, saved, and reflected immediately', () async {
    final error = await container
        .read(profileControllerProvider('u1').notifier)
        .updateDisplayName('  Kaleab Tesfaye  ');

    expect(error, isNull);
    expect(repository.names, ['Kaleab Tesfaye']);
    expect(container.read(controller).value?.displayName, 'Kaleab Tesfaye');
  });

  test('blank and overlong display names are rejected before saving', () async {
    final notifier = container.read(
      profileControllerProvider('u1').notifier,
    );

    expect(await notifier.updateDisplayName('   '), isNotEmpty);
    expect(
      await notifier.updateDisplayName('a' * (maxDisplayNameLength + 1)),
      isNotEmpty,
    );

    expect(repository.names, isEmpty);
    expect(container.read(controller).value?.displayName, 'Kaleab');
  });

  test('an unchanged display name does not touch the repository', () async {
    final error = await container
        .read(profileControllerProvider('u1').notifier)
        .updateDisplayName('Kaleab');

    expect(error, isNull);
    expect(repository.names, isEmpty);
  });

  test('selecting an animal saves its catalog id', () async {
    final error = await container
        .read(profileControllerProvider('u1').notifier)
        .updateAvatar('avatar_ibex');

    expect(error, isNull);
    expect(repository.avatars, ['avatar_ibex']);
    expect(container.read(controller).value?.avatarId, 'avatar_ibex');
  });

  test('unknown animal ids are refused without a write', () async {
    final error = await container
        .read(profileControllerProvider('u1').notifier)
        .updateAvatar('avatar_dragon');

    expect(error, isNotEmpty);
    expect(repository.avatars, isEmpty);
    expect(container.read(controller).value?.avatarId, 'avatar_wolf');
  });

  test('a failed save rolls the optimistic change back', () async {
    repository.failWith = const ProfileFailure('Nope, not today.');

    final nameError = await container
        .read(profileControllerProvider('u1').notifier)
        .updateDisplayName('Someone Else');
    expect(nameError, 'Nope, not today.');
    expect(container.read(controller).value?.displayName, 'Kaleab');

    final avatarError = await container
        .read(profileControllerProvider('u1').notifier)
        .updateAvatar('avatar_lion');
    expect(avatarError, 'Nope, not today.');
    expect(container.read(controller).value?.avatarId, 'avatar_wolf');
  });
}
