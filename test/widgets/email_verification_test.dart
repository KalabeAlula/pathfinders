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
  _FakeAuthRepository({this.verifyFailure, this.resendFailure});

  AuthFailure? verifyFailure;
  AuthFailure? resendFailure;
  AuthFailure? signInFailure;

  int resendCount = 0;
  String? verifiedEmail;
  String? verifiedCode;

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> watchSession() => const Stream<AuthSession?>.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {
    final failure = signInFailure;
    if (failure != null) throw failure;
  }

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
  }) async {
    verifiedEmail = email;
    verifiedCode = code;
    final failure = verifyFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> resendSignUpCode({required String email}) async {
    resendCount++;
    final failure = resendFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> signOut() async {}
}

const _email = 'kaleab@example.com';

Future<_FakeAuthRepository> _pumpAuthScreen(
  WidgetTester tester, {
  _FakeAuthRepository? repository,
  double textScale = 1,
}) async {
  final repo = repository ?? _FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const AuthScreen(),
      ),
    ),
  );
  return repo;
}

Future<_FakeAuthRepository> _openVerification(
  WidgetTester tester, {
  _FakeAuthRepository? repository,
  double textScale = 1,
}) async {
  final repo = await _pumpAuthScreen(
    tester,
    repository: repository,
    textScale: textScale,
  );
  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('auth-display-name')),
    'Kaleab',
  );
  await tester.enterText(find.byKey(const ValueKey('auth-email')), _email);
  await tester.enterText(
    find.byKey(const ValueKey('auth-password')),
    'secret123',
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
  await tester.pump();
  await tester.pump();
  return repo;
}

/// Unmounts the tree so the countdown timer is cancelled before teardown.
Future<void> _dismount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

TextButton _resendButton(WidgetTester tester) =>
    tester.widget<TextButton>(find.byKey(const ValueKey('otp-resend')));

void main() {
  testWidgets('sign-up opens the code step and auto-submits six digits', (
    tester,
  ) async {
    final repo = await _openVerification(tester);

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('We sent a 6-digit code to $_email.'), findsOneWidget);
    expect(find.text('Resend code in 1:00'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
    await tester.pump();
    await tester.pump();

    expect(repo.verifiedEmail, _email);
    expect(repo.verifiedCode, '123456');

    await _dismount(tester);
  });

  testWidgets('a pasted code with separators still submits the six digits', (
    tester,
  ) async {
    final repo = await _openVerification(tester);

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '123 456');
    await tester.pump();
    await tester.pump();

    expect(repo.verifiedCode, '123456');

    await _dismount(tester);
  });

  testWidgets('a wrong code shows an error, clears the boxes, and retries', (
    tester,
  ) async {
    final repo = await _openVerification(
      tester,
      repository: _FakeAuthRepository(
        verifyFailure: const AuthFailure(
          'That code is incorrect. Check the email and try again.',
          code: 'otp_expired',
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '000000');
    await tester.pump();
    await tester.pump();

    expect(
      find.text('That code is incorrect. Check the email and try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('otp-field')))
          .controller
          ?.text,
      isEmpty,
    );

    repo.verifyFailure = null;
    await tester.enterText(find.byKey(const ValueKey('otp-field')), '654321');
    await tester.pump();
    await tester.pump();

    expect(
      find.text('That code is incorrect. Check the email and try again.'),
      findsNothing,
    );
    expect(repo.verifiedCode, '654321');

    await _dismount(tester);
  });

  testWidgets('an expired code reports expiry inline', (tester) async {
    await _openVerification(
      tester,
      repository: _FakeAuthRepository(
        verifyFailure: const AuthFailure(
          'That code has expired. Request a new one.',
          code: 'otp_expired',
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('otp-field')), '111111');
    await tester.pump();
    await tester.pump();

    expect(
      find.text('That code has expired. Request a new one.'),
      findsOneWidget,
    );

    await _dismount(tester);
  });

  testWidgets('resend stays disabled for 60 seconds, then sends again', (
    tester,
  ) async {
    final repo = await _openVerification(tester);

    expect(_resendButton(tester).onPressed, isNull);

    await tester.pump(const Duration(seconds: 59));
    expect(find.text('Resend code in 0:01'), findsOneWidget);
    expect(_resendButton(tester).onPressed, isNull);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Resend code'), findsOneWidget);
    expect(_resendButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('otp-resend')));
    await tester.pump();
    await tester.pump();

    expect(repo.resendCount, 1);
    expect(find.text('Resend code in 1:00'), findsOneWidget);
    expect(_resendButton(tester).onPressed, isNull);

    await _dismount(tester);
  });

  testWidgets('a failed resend shows the error and allows another try', (
    tester,
  ) async {
    await _openVerification(
      tester,
      repository: _FakeAuthRepository(
        resendFailure: const AuthFailure(
          'Too many attempts. Wait a minute, then try again.',
          code: 'over_email_send_rate_limit',
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.byKey(const ValueKey('otp-resend')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Too many attempts. Wait a minute, then try again.'),
      findsOneWidget,
    );
    expect(_resendButton(tester).onPressed, isNotNull);

    await _dismount(tester);
  });

  testWidgets('edit email returns to the sign-up form with the email kept', (
    tester,
  ) async {
    await _openVerification(tester);

    await tester.tap(find.byKey(const ValueKey('otp-edit-email')));
    await tester.pump();

    expect(find.text('Verify your email'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('auth-email')))
          .controller
          ?.text,
      _email,
    );

    await _dismount(tester);
  });

  testWidgets('signing in with an unverified email opens the code step', (
    tester,
  ) async {
    final repo = await _pumpAuthScreen(tester);
    repo.signInFailure = const AuthFailure(
      'Verify your email first — enter the 6-digit code we sent you.',
      code: 'email_not_confirmed',
    );

    await tester.enterText(find.byKey(const ValueKey('auth-email')), _email);
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('We sent a 6-digit code to $_email.'), findsOneWidget);

    await _dismount(tester);
  });

  testWidgets('the code step fits a 360dp phone at 1.2x text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openVerification(tester, textScale: 1.2);

    expect(find.text('Verify your email'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _dismount(tester);
  });
}
