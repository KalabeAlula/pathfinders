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
  Future<void> signIn({required String email, required String password}) async {
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
  Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        type: sb.OtpType.signup,
        email: email.trim(),
        token: code.trim(),
      );
    } on sb.AuthException catch (error) {
      throw _mapOtpFailure(
        error,
        fallback: 'Could not verify that code. Check your connection.',
      );
    }
  }

  @override
  Future<void> resendSignUpCode({required String email}) async {
    try {
      await _client.auth.resend(type: sb.OtpType.signup, email: email.trim());
    } on sb.AuthException catch (error) {
      throw _mapOtpFailure(
        error,
        fallback: 'Could not send a new code. Check your connection.',
      );
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on sb.AuthException catch (error) {
      throw _mapOtpFailure(
        error,
        fallback: 'Could not send a reset code. Check your connection.',
      );
    }
  }

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        type: sb.OtpType.recovery,
        email: email.trim(),
        token: code.trim(),
      );
    } on sb.AuthException catch (error) {
      throw _mapOtpFailure(
        error,
        fallback: 'Could not verify that code. Check your connection.',
      );
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
    } on sb.AuthException catch (error) {
      throw _mapPasswordFailure(error);
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
        'Verify your email first — enter the 6-digit code we sent you.',
      'user_already_exists' ||
      'email_exists' => 'That email already has an account. Sign in instead.',
      'weak_password' => 'Use at least 6 characters for your password.',
      'over_request_rate_limit' || 'over_email_send_rate_limit' =>
        'Too many attempts. Wait a minute, then try again.',
      'signup_disabled' => 'New accounts are paused right now.',
      _ => null,
    };
    return AuthFailure(
      message ?? 'Could not reach your account. Check your connection.',
      code: code,
    );
  }

  static AuthFailure _mapOtpFailure(
    sb.AuthException error, {
    required String fallback,
  }) {
    final code = error.code;
    final details = error.message.toLowerCase();
    final message = switch (code) {
      // Supabase reports both a wrong and an expired code as otp_expired, so
      // the server copy is the only way to tell them apart.
      'otp_expired'
          when details.contains('invalid') && !details.contains('expired') =>
        'That code is incorrect. Check the email and try again.',
      'otp_expired' => 'That code has expired. Request a new one.',
      'over_request_rate_limit' || 'over_email_send_rate_limit' =>
        'Too many attempts. Wait a minute, then try again.',
      _ => null,
    };
    return AuthFailure(message ?? fallback, code: code);
  }

  static AuthFailure _mapPasswordFailure(sb.AuthException error) {
    final code = error.code;
    final message = switch (code) {
      'weak_password' =>
        'Use at least 8 characters with a mix of letters and numbers.',
      'same_password' => 'Choose a password different from your current one.',
      'over_request_rate_limit' || 'over_email_send_rate_limit' =>
        'Too many attempts. Wait a minute, then try again.',
      _ => null,
    };
    return AuthFailure(
      message ?? 'Could not update your password. Try again.',
      code: code,
    );
  }
}
