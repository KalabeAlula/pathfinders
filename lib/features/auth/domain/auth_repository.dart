import 'auth_session.dart';

/// What happened after asking Supabase to create an account.
///
/// When project email confirmation is on, sign-up succeeds without a session
/// and the person has to enter the 6-digit code emailed to them.
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

  /// Redeems the 6-digit sign-up code and, on success, starts the session.
  Future<void> verifySignUpCode({required String email, required String code});

  Future<void> resendSignUpCode({required String email});

  /// Emails a 6-digit recovery code. Always succeeds from the caller's point
  /// of view so the response cannot reveal which addresses have accounts.
  Future<void> requestPasswordReset({required String email});

  /// Redeems the recovery code, putting the client into a recovery session
  /// that [updatePassword] then uses.
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  });

  Future<void> updatePassword({required String newPassword});

  Future<void> signOut();
}
