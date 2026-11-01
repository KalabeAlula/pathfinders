import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../app/widgets/onboarding_shell.dart';
import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _busy = false;
  String? _error;
  String? _pendingEmail;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();

    try {
      if (_mode == _AuthMode.signIn) {
        await repository.signIn(
          email: email,
          password: _passwordController.text,
        );
      } else {
        final outcome = await repository.signUp(
          email: email,
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
        if (outcome.needsEmailConfirmation && mounted) {
          setState(() {
            _pendingEmail = email;
            _passwordController.clear();
          });
        }
      }
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _returnToSignIn() {
    setState(() {
      _pendingEmail = null;
      _mode = _AuthMode.signIn;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pendingEmail = _pendingEmail;

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandHeader(
            subtitle: 'A quiet place for your small circle of people.',
          ),
          const SizedBox(height: AppSpacing.xl),
          if (pendingEmail != null)
            BentoCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.mark_email_unread_rounded,
                    size: 30,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Check your inbox',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We sent a confirmation link to $pendingEmail. Open it once, '
                    'then come back and sign in.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _returnToSignIn,
                      child: const Text('Back to sign in'),
                    ),
                  ),
                ],
              ),
            )
          else
            BentoCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedToggle<_AuthMode>(
                      values: const [_AuthMode.signIn, _AuthMode.signUp],
                      labels: const ['Sign in', 'Create account'],
                      selected: _mode,
                      onChanged: _switchMode,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_mode == _AuthMode.signUp) ...[
                      TextFormField(
                        key: const ValueKey('auth-display-name'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: onboardingFieldDecoration(
                          context,
                          label: 'Display name',
                          hint: 'What the crew calls you',
                          icon: Icons.badge_outlined,
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) return 'Add a name your crew knows.';
                          if (name.length > 40) {
                            return 'Keep it under 40 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      key: const ValueKey('auth-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
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
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const ValueKey('auth-password'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        _mode == _AuthMode.signIn
                            ? AutofillHints.password
                            : AutofillHints.newPassword,
                      ],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: onboardingFieldDecoration(
                        context,
                        label: 'Password',
                        hint: _mode == _AuthMode.signIn
                            ? 'Your password'
                            : 'At least 6 characters',
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
                        if (password.isEmpty) return 'Enter your password.';
                        if (_mode == _AuthMode.signUp && password.length < 6) {
                          return 'Use at least 6 characters.';
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
                      label: _mode == _AuthMode.signIn
                          ? 'Sign in'
                          : 'Create account',
                      busy: _busy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _mode == _AuthMode.signIn
                          ? 'New here? Create an account first, then start or join a circle.'
                          : 'You will create your circle on the next screen.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10.5,
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
