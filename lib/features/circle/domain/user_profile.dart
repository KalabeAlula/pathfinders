/// A circle member as shown across the app.
///
/// [avatarColor] is a packed ARGB value so the domain stays free of Flutter
/// imports; the presentation layer turns it into a [Color].
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.avatarColor,
    this.avatarId,
    this.statusLine,
  });

  final String id;
  final String displayName;
  final int avatarColor;

  /// Catalog id such as `avatar_wolf`; null for rows that predate avatars.
  final String? avatarId;
  final String? statusLine;

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get firstName => displayName.split(' ').first;
}
