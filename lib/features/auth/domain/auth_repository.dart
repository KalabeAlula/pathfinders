import 'auth_session.dart';

/// What happened after asking Supabase to create an account.
///
/// When project email confirmation is on, sign-up succeeds without a session
/// and the person has to open the link in their inbox first.
class SignUpOutcome {
  const SignUpOutcome({
    required this.session,
    required this.needsEmailConfirmation,
  });

  final AuthSession? session;
  final bool needsEmailConfirmation;
}

abstract interface class AuthRepository {
  AuthSession? get currentSession;

  /// Emits the current session immediately, then every auth change.
  Stream<AuthSession?> watchSession();

  Future<void> signIn({required String email, required String password});

  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();
}
