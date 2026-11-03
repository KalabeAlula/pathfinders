import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../app/widgets/onboarding_shell.dart';
import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';
import 'widgets/code_input.dart';

/// Inline step that redeems the 6-digit sign-up code emailed by Supabase.
///
/// A successful verification starts the Supabase session, so the surrounding
/// [SessionGate] moves straight on to circle onboarding or the dashboard.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onEditEmail,
  });

  final String email;
  final VoidCallback onEditEmail;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  static const _resendSeconds = 60;

  final _codeKey = GlobalKey<CodeInputState>();

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _busy = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  Future<void> _verify(String code) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .verifySignUpCode(email: widget.email, code: code);
      // The auth stream flips SessionGate to onboarding/dashboard.
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
      _codeKey.currentState?.clear();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Try again.');
      _codeKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;

    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .resendSignUpCode(email: widget.email);
      if (!mounted) return;
      setState(() => _secondsLeft = _resendSeconds);
      _startCountdown();
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

    return BentoCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_read_rounded, size: 30, color: scheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Verify your email',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'We sent a 6-digit code to ${widget.email}.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          CodeInput(
            key: _codeKey,
            error: _error,
            enabled: !_busy,
            onChanged: (_) => setState(() => _error = null),
            onCompleted: (code) => unawaited(_verify(code)),
          ),
          if (_busy) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Checking code…',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            InlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton(
              key: const ValueKey('otp-resend'),
              onPressed: _secondsLeft <= 0 && !_resending ? _resend : null,
              child: Text(_resendLabel),
            ),
          ),
          Center(
            child: TextButton.icon(
              key: const ValueKey('otp-edit-email'),
              onPressed: _busy ? null : widget.onEditEmail,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit email'),
            ),
          ),
        ],
      ),
    );
  }
}
