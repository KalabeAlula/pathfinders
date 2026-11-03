import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_theme.dart';
import 'package:pathfinders/features/auth/application/auth_providers.dart';
import 'package:pathfinders/features/auth/domain/auth_failure.dart';
import 'package:pathfinders/features/auth/domain/auth_repository.dart';
import 'package:pathfinders/features/auth/domain/auth_session.dart';
import 'package:pathfinders/features/auth/presentation/auth_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.resetFailure,
    this.recoveryFailure,
    this.updateFailure,
  });

  AuthFailure? resetFailure;
  AuthFailure? recoveryFailure;
  AuthFailure? updateFailure;

  int resetCount = 0;
  String? resetEmail;
  String? recoveryEmail;
  String? recoveryCode;
  String? updatedPassword;

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> watchSession() => const Stream<AuthSession?>.empty();

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return const SignUpOutcome(session: null, needsEmailConfirmation: true);
  }

  @override
  Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) async {}

  @override
  Future<void> resendSignUpCode({required String email}) async {}

  @override
  Future<void> requestPasswordReset({required String email}) async {
    resetCount++;
    resetEmail = email;
    final failure = resetFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    recoveryEmail = email;
    recoveryCode = code;
    final failure = recoveryFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updatedPassword = newPassword;
    final failure = updateFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> signOut() async {}
}

const _email = 'kaleab@example.com';

Future<_FakeAuthRepository> _pumpAuthScreen(
  WidgetTester tester, {
  _FakeAuthRepository? repository,
}) async {
  final repo = repository ?? _FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(theme: AppTheme.light(), home: const AuthScreen()),
    ),
  );
  return repo;
}

Future<_FakeAuthRepository> _openRequestScreen(
  WidgetTester tester, {
  _FakeAuthRepository? repository,
}) async {
  final repo = await _pumpAuthScreen(tester, repository: repository);
  await tester.tap(find.byKey(const ValueKey('auth-forgot-password')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return repo;
}

Future<_FakeAuthRepository> _openConfirmScreen(
  WidgetTester tester, {
  _FakeAuthRepository? repository,
}) async {
  final repo = await _openRequestScreen(tester, repository: repository);
  await tester.enterText(find.byKey(const ValueKey('reset-email')), _email);
  await tester.tap(find.widgetWithText(FilledButton, 'Send reset code'));
  await tester.pump();
  await tester.pump();
  return repo;
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Update password');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('the sign-in screen offers a forgot-password entry', (
    tester,
  ) async {
    await _pumpAuthScreen(tester);

    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('auth-forgot-password')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('Send reset code'), findsOneWidget);
  });

  testWidgets('an invalid email is rejected before any request is made', (
    tester,
  ) async {
    final repo = await _openRequestScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('reset-email')), 'nope');
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset code'));
    await tester.pump();

    expect(find.text('That email looks incomplete.'), findsOneWidget);
    expect(repo.resetCount, 0);
  });

  testWidgets('a failed reset request shows the error and stays put', (
    tester,
  ) async {
    await _openRequestScreen(
      tester,
      repository: _FakeAuthRepository(
        resetFailure: const AuthFailure(
          'Could not send a reset code. Check your connection.',
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('reset-email')), _email);
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset code'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Could not send a reset code. Check your connection.'),
      findsOneWidget,
    );
    expect(find.text('Set new password'), findsNothing);
  });

  testWidgets('a valid email requests a code and opens the confirm step', (
    tester,
  ) async {
    final repo = await _openConfirmScreen(tester);

    expect(repo.resetEmail, _email);
    expect(find.text('Set new password'), findsOneWidget);
    expect(
      find.text('We sent a 6-digit recovery code to $_email.'),
      findsOneWidget,
    );
  });

  testWidgets('mismatched passwords are flagged before verifying the code', (
    tester,
  ) async {
    final repo = await _openConfirmScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
    await tester.enterText(
      find.byKey(const ValueKey('recovery-password')),
      'newpassword8',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-confirm')),
      'different8',
    );
    await _tapSubmit(tester);

    expect(find.text('Passwords don\u2019t match.'), findsOneWidget);
    expect(repo.recoveryCode, isNull);
  });

  testWidgets('a short password is rejected with a clear message', (
    tester,
  ) async {
    await _openConfirmScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
    await tester.enterText(
      find.byKey(const ValueKey('recovery-password')),
      'short',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-confirm')),
      'short',
    );
    await _tapSubmit(tester);

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });

  testWidgets('submitting without a code asks for it first', (tester) async {
    final repo = await _openConfirmScreen(tester);

    await tester.enterText(
      find.byKey(const ValueKey('recovery-password')),
      'newpassword8',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-confirm')),
      'newpassword8',
    );
    await _tapSubmit(tester);

    expect(
      find.text('Enter the 6-digit code from your email first.'),
      findsOneWidget,
    );
    expect(repo.recoveryCode, isNull);
  });

  testWidgets('a valid code and password verify, update, and confirm', (
    tester,
  ) async {
    final repo = await _openConfirmScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '987654');
    await tester.enterText(
      find.byKey(const ValueKey('recovery-password')),
      'newpassword8',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-confirm')),
      'newpassword8',
    );
    await _tapSubmit(tester);
    await tester.pump();

    expect(repo.recoveryEmail, _email);
    expect(repo.recoveryCode, '987654');
    expect(repo.updatedPassword, 'newpassword8');
    expect(find.text('Password updated'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Back at the sign-in root after popping the recovery stack.
    expect(find.text('Set new password'), findsNothing);
  });

  testWidgets('an invalid recovery code shows an error and skips the update', (
    tester,
  ) async {
    final repo = await _openConfirmScreen(
      tester,
      repository: _FakeAuthRepository(
        recoveryFailure: const AuthFailure(
          'That code has expired. Request a new one.',
          code: 'otp_expired',
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '000000');
    await tester.enterText(
      find.byKey(const ValueKey('recovery-password')),
      'newpassword8',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-confirm')),
      'newpassword8',
    );
    await _tapSubmit(tester);
    await tester.pump();

    expect(
      find.text('That code has expired. Request a new one.'),
      findsOneWidget,
    );
    expect(repo.updatedPassword, isNull);

    // Retry with a good code.
    repo.recoveryFailure = null;
    await tester.enterText(find.byKey(const ValueKey('otp-field')), '111222');
    await _tapSubmit(tester);
    await tester.pump();

    expect(repo.recoveryCode, '111222');
    expect(repo.updatedPassword, 'newpassword8');
  });

  testWidgets('a weak password from the server stays on the form', (
    tester,
  ) async {
    final repo = await _openConfirmScreen(
      tester,
      repository: _FakeAuthRepository(
        updateFailure: const AuthFailure(
          'Use at least 8 characters with a mix of letters and numbers.',
          code: 'weak_password',
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
    await tester.enterText(
      find.byKey(const ValueKey('recovery-password')),
      'newpassword8',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-confirm')),
      'newpassword8',
    );
    await _tapSubmit(tester);
    await tester.pump();

    expect(
      find.text('Use at least 8 characters with a mix of letters and numbers.'),
      findsOneWidget,
    );
    expect(repo.recoveryCode, '123456');
  });

  testWidgets('resend stays on cooldown for 60 seconds, then resends', (
    tester,
  ) async {
    final repo = await _openConfirmScreen(tester);

    final button = tester.widget<TextButton>(
      find.byKey(const ValueKey('recovery-resend')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Resend code in 1:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 60));
    expect(find.text('Resend code'), findsOneWidget);

    final resend = find.byKey(const ValueKey('recovery-resend'));
    await tester.ensureVisible(resend);
    await tester.tap(resend);
    await tester.pump();
    await tester.pump();

    expect(repo.resetCount, 2);
    expect(find.text('Resend code in 1:00'), findsOneWidget);
  });
}
