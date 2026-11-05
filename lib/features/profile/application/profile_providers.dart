import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/animal_avatar.dart';
import '../domain/profile_details.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';

part 'profile_providers.g.dart';

const int maxDisplayNameLength = 40;

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref, String userId) =>
    SupabaseProfileRepository(
      ref.watch(supabaseClientProvider),
      userId: userId,
    );

/// The member's own profile, kept live so the header and avatar picker follow
/// changes made on another device.
@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  StreamSubscription<ProfileDetails>? _subscription;

  @override
  AsyncValue<ProfileDetails> build(String userId) {
    final repository = ref.watch(profileRepositoryProvider(userId));
    _subscription?.cancel();
    _subscription = repository.watchProfile().listen(
      (profile) {
        if (ref.mounted) state = AsyncData(profile);
      },
      onError: (Object error, StackTrace stack) {
        if (ref.mounted && !state.hasValue) state = AsyncError(error, stack);
      },
    );
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return const AsyncLoading();
  }

  /// Returns null on success, or copy explaining what to fix.
  Future<String?> updateDisplayName(String raw) async {
    final profile = state.value;
    if (profile == null) return 'Your profile is still loading.';

    final name = raw.trim();
    if (name.isEmpty) {
      return 'Add a name so your circle knows who is on the map.';
    }
    if (name.length > maxDisplayNameLength) {
      return 'Names are limited to $maxDisplayNameLength characters.';
    }
    if (name == profile.displayName) return null;

    return _persist(
      optimistic: profile.copyWith(displayName: name),
      previous: profile,
      write: () => ref
          .read(profileRepositoryProvider(userId))
          .updateDisplayName(name),
    );
  }

  /// Returns null on success, or copy explaining what went wrong.
  Future<String?> updateAvatar(String avatarId) async {
    final profile = state.value;
    if (profile == null) return 'Your profile is still loading.';

    final avatar = AnimalAvatar.tryById(avatarId);
    if (avatar == null) return 'That companion is not available.';
    if (avatar.id == profile.avatarId) return null;

    return _persist(
      optimistic: profile.copyWith(avatarId: avatar.id),
      previous: profile,
      write: () => ref
          .read(profileRepositoryProvider(userId))
          .updateAvatar(avatar.id),
    );
  }

  Future<String?> _persist({
    required ProfileDetails optimistic,
    required ProfileDetails previous,
    required Future<void> Function() write,
  }) async {
    state = AsyncData(optimistic);
    try {
      await write();
      return null;
    } on ProfileFailure catch (error) {
      if (ref.mounted) state = AsyncData(previous);
      return error.message;
    } catch (_) {
      if (ref.mounted) state = AsyncData(previous);
      return 'Could not save your profile. Check your connection and try again.';
    }
  }
}
