import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../app/widgets/onboarding_shell.dart';
import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';
import 'widgets/code_input.dart';

/// Redeems the emailed 6-digit recovery code, then sets the new password
/// inside the recovery session it opens.
///
/// On success the person is signed in, so popping back to the root lets
/// [SessionGate] render the dashboard.
class ResetPasswordConfirmScreen extends ConsumerStatefulWidget {
  const ResetPasswordConfirmScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends ConsumerState<ResetPasswordConfirmScreen> {
  static const _resendSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<CodeInputState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  String _code = '';
  bool _busy = false;
  bool _resending = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) timer.cancel();
      });
    });
  }

  void _clearErrors() {
    if (_error != null || _codeError != null) {
      setState(() {
        _error = null;
        _codeError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_code)) {
      setState(() {
        _error = 'Enter the 6-digit code from your email first.';
        _codeError = 'Enter the 6-digit code from your email first.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _codeError = null;
    });

    final repository = ref.read(authRepositoryProvider);
    try {
      await repository.verifyRecoveryCode(email: widget.email, code: _code);
      await repository.updatePassword(newPassword: _passwordController.text);
      if (!mounted) return;
      await _showSuccessAndLeave();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      final isPasswordIssue =
          failure.code == 'weak_password' || failure.code == 'same_password';
      setState(() {
        _error = failure.message;
        // OTP problems belong on the code input; password problems on the form.
        _codeError = isPasswordIssue ? null : failure.message;
      });
      if (!isPasswordIssue) {
        _code = '';
        _codeKey.currentState?.clear();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSuccessAndLeave() async {
    final scheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline_rounded,
          color: scheme.primary,
          size: 34,
        ),
        title: const Text('Password updated'),
        content: const Text('Your password was updated and you are signed in.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;

    setState(() {
      _resending = true;
      _error = null;
      _codeError = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: widget.email);
      if (!mounted) return;
      setState(() => _secondsLeft = _resendSeconds);
      _startCountdown();
      _code = '';
      _codeKey.currentState?.clear();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not send a new code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String get _resendLabel {
    if (_secondsLeft <= 0) return 'Resend code';
    final minutes = _secondsLeft ~/ 60;
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return 'Resend code in $minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandHeader(
            subtitle: 'A quiet place for your small circle of people.',
          ),
          const SizedBox(height: AppSpacing.xl),
          BentoCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_reset_rounded,
                    size: 30,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Set new password',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We sent a 6-digit recovery code to ${widget.email}.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CodeInput(
                    key: _codeKey,
                    error: _codeError,
                    enabled: !_busy,
                    onChanged: (value) {
                      _code = value;
                      _clearErrors();
                    },
                    onCompleted: (code) => setState(() => _code = code),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    key: const ValueKey('recovery-password'),
                    controller: _passwordController,
                    enabled: !_busy,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: onboardingFieldDecoration(
                      context,
                      label: 'New password',
                      hint: 'At least 8 characters',
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) return 'Enter a new password.';
                      if (password.length < 8) {
                        return 'Use at least 8 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const ValueKey('recovery-confirm'),
                    controller: _confirmController,
                    enabled: !_busy,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: onboardingFieldDecoration(
                      context,
                      label: 'Confirm new password',
                      hint: 'Repeat it once more',
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        tooltip: _obscureConfirm
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Confirm your new password.';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords don\u2019t match.';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    InlineError(message: _error!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AuthSubmitButton(
                    label: 'Update password',
                    busy: _busy,
                    onPressed: _submit,
                  ),
                  Center(
                    child: TextButton(
                      key: const ValueKey('recovery-resend'),
                      onPressed: _secondsLeft <= 0 && !_resending
                          ? _resend
                          : null,
                      child: Text(_resendLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
