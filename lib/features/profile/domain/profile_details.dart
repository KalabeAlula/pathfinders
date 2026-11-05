/// The signed-in member's editable identity.
class ProfileDetails {
  const ProfileDetails({
    required this.userId,
    required this.displayName,
    required this.avatarId,
    required this.createdAt,
  });

  final String userId;
  final String displayName;

  /// Catalog id, e.g. `avatar_wolf`.
  final String avatarId;
  final DateTime createdAt;

  ProfileDetails copyWith({String? displayName, String? avatarId}) {
    return ProfileDetails(
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      createdAt: createdAt,
    );
  }
}
