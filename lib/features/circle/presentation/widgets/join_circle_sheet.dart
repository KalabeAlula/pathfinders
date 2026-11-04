import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/onboarding_shell.dart';
import '../../application/circle_providers.dart';
import '../../domain/circle_failure.dart';

Future<void> showJoinCircleSheet(
  BuildContext context, {
  required String userId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => JoinCircleSheet(userId: userId),
  );
}

/// Redeems an invite code and switches straight to the joined group.
class JoinCircleSheet extends ConsumerStatefulWidget {
  const JoinCircleSheet({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<JoinCircleSheet> createState() => _JoinCircleSheetState();
}

class _JoinCircleSheetState extends ConsumerState<JoinCircleSheet> {
  final _controller = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Invite codes are six characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final circle = await ref
          .read(circleRepositoryProvider(widget.userId))
          .joinCircle(code: code);
      await ref
          .read(activeCircleControllerProvider(widget.userId).notifier)
          .select(circle.id);
      if (!mounted) return;
      ref.invalidate(circlesProvider(widget.userId));
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Welcome to ${circle.name}!')),
      );
    } on CircleFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not join that circle. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Join a Circle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Enter the invite code shared by your circle creator.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const ValueKey('join-code'),
                  controller: _controller,
                  autofocus: true,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _submit(),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(letterSpacing: 6),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(6),
                    _UpperCaseFormatter(),
                  ],
                  decoration: onboardingFieldDecoration(
                    context,
                    label: 'Invite code',
                    hint: 'A2B3C4',
                    icon: Icons.key_rounded,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InlineError(message: _error!),
                ],
                const SizedBox(height: AppSpacing.lg),
                AuthSubmitButton(
                  key: const ValueKey('join-submit'),
                  label: 'Join Circle',
                  busy: _busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
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
