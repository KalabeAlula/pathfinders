import 'profile_details.dart';

abstract interface class ProfileRepository {
  /// Emits the stored profile, then every realtime change to it.
  Stream<ProfileDetails> watchProfile();

  Future<void> updateDisplayName(String displayName);

  Future<void> updateAvatar(String avatarId);
}
