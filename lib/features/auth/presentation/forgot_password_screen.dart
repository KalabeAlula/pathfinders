import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../app/widgets/onboarding_shell.dart';
import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';
import 'reset_password_confirm_screen.dart';

/// Asks Supabase to email a 6-digit recovery code, then hands off to
/// [ResetPasswordConfirmScreen].
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: email);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordConfirmScreen(email: email),
        ),
      );
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                  Text(
                    'Reset your password',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your account email and we will send a recovery '
                    'code.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    key: const ValueKey('reset-email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: onboardingFieldDecoration(
                      context,
                      label: 'Email',
                      hint: 'you@example.com',
                      icon: Icons.alternate_email_rounded,
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Enter your email.';
                      final looksValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(email);
                      if (!looksValid) return 'That email looks incomplete.';
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    InlineError(message: _error!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AuthSubmitButton(
                    label: 'Send reset code',
                    busy: _busy,
                    onPressed: _submit,
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
