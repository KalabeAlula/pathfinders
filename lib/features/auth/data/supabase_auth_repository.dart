import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  AuthSession? get currentSession => _toSession(_client.auth.currentSession);

  @override
  Stream<AuthSession?> watchSession() async* {
    yield currentSession;
    yield* _client.auth.onAuthStateChange
        .map((state) => _toSession(state.session))
        .distinct();
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on sb.AuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      return SignUpOutcome(
        session: _toSession(response.session),
        needsEmailConfirmation: response.session == null,
      );
    } on sb.AuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on sb.AuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  static AuthSession? _toSession(sb.Session? session) {
    if (session == null) return null;
    return AuthSession(
      userId: session.user.id,
      email: session.user.email ?? '',
    );
  }

  static AuthFailure _mapFailure(sb.AuthException error) {
    final code = error.code;
    final message = switch (code) {
      'invalid_credentials' => 'That email and password do not match.',
      'email_not_confirmed' =>
        'Confirm your email first — the link is in your inbox.',
      'user_already_exists' ||
      'email_exists' =>
        'That email already has an account. Sign in instead.',
      'weak_password' => 'Use at least 6 characters for your password.',
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' =>
        'Too many attempts. Wait a minute, then try again.',
      'signup_disabled' => 'New accounts are paused right now.',
      _ => null,
    };
    return AuthFailure(
      message ?? 'Could not reach your account. Check your connection.',
      code: code,
    );
  }
}
