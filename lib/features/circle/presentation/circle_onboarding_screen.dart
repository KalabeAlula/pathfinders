import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../app/widgets/onboarding_shell.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_failure.dart';
import '../application/circle_providers.dart';
import '../domain/circle_failure.dart';
import '../domain/group_type.dart';

enum _SetupMode { create, join }

class CircleOnboardingScreen extends ConsumerStatefulWidget {
  const CircleOnboardingScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<CircleOnboardingScreen> createState() =>
      _CircleOnboardingScreenState();
}

class _CircleOnboardingScreenState
    extends ConsumerState<CircleOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  _SetupMode _mode = _SetupMode.create;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _switchMode(_SetupMode mode) {
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

    try {
      final repository =
          ref.read(circleRepositoryProvider(widget.userId));
      switch (_mode) {
        case _SetupMode.create:
          final type = GroupType.friends;
          final companion = type.defaultPet;
          await repository.createCircle(
            name: _nameController.text,
            type: type,
            petId: companion.id,
            petName: companion.defaultName,
          );
        case _SetupMode.join:
          await repository.joinCircle(code: _codeController.text);
      }
      ref.invalidate(circlesProvider(widget.userId));
      ref.invalidate(circleSnapshotProvider(widget.userId));
    } on CircleFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final email = ref.watch(authSessionProvider).value?.email ?? '';
    final creating = _mode == _SetupMode.create;

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandHeader(
            title: 'One more step',
            subtitle:
                'Circles hold two to six people, depending on the group type — '
                'the ones you actually travel through life with.',
          ),
          const SizedBox(height: AppSpacing.xl),
          BentoCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedToggle<_SetupMode>(
                    values: const [_SetupMode.create, _SetupMode.join],
                    labels: const ['Start a circle', 'Join with a code'],
                    selected: _mode,
                    onChanged: _switchMode,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (creating)
                    TextFormField(
                      key: const ValueKey('circle-name'),
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      maxLength: 40,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: onboardingFieldDecoration(
                        context,
                        label: 'Circle name',
                        hint: 'Bole Crew',
                        icon: Icons.groups_rounded,
                      ).copyWith(counterText: ''),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) return 'Give your circle a name.';
                        if (name.length > 40) {
                          return 'Keep it under 40 characters.';
                        }
                        return null;
                      },
                    )
                  else
                    TextFormField(
                      key: const ValueKey('circle-code'),
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      onFieldSubmitted: (_) => _submit(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            letterSpacing: 6,
                          ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(6),
                        _UpperCaseFormatter(),
                      ],
                      decoration: onboardingFieldDecoration(
                        context,
                        label: 'Invite code',
                        hint: 'A2B3C4',
                        icon: Icons.key_rounded,
                      ),
                      validator: (value) {
                        final code = value?.trim().toUpperCase() ?? '';
                        if (code.isEmpty) return 'Enter the invite code.';
                        if (code.length != 6) {
                          return 'Invite codes are six characters.';
                        }
                        final usesAllowedCharacters =
                            RegExp(r'^[A-HJ-NP-Z2-9]{6}$').hasMatch(code);
                        if (!usesAllowedCharacters) {
                          return 'That code has a character we do not use. '
                              'Check it again.';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 6),
                  Text(
                    creating
                        ? 'You can share the invite code right after creating it.'
                        : 'Ask the person who made the circle for its code.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10.5,
                        ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    InlineError(message: _error!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AuthSubmitButton(
                    label: creating ? 'Create circle' : 'Join circle',
                    busy: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (email.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 13,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Signed in as $email',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Center(
            child: TextButton(
              onPressed: _signOut,
              child: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
