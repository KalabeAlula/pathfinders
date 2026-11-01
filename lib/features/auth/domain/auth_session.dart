/// The signed-in identity. A null session means signed out.
class AuthSession {
  const AuthSession({required this.userId, required this.email});

  final String userId;
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession && other.userId == userId && other.email == email;

  @override
  int get hashCode => Object.hash(userId, email);
}
