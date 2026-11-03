import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/onboarding_shell.dart';
import '../../circle/presentation/circle_gate.dart';
import '../application/auth_providers.dart';
import 'auth_screen.dart';

/// Sends the user to sign-in, circle setup, or the dashboard based on the
/// Supabase auth stream.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    return session.when(
      data: (value) {
        if (value == null) return const AuthScreen();
        return CircleGate(key: ValueKey(value.userId), userId: value.userId);
      },
      loading: () => const GateStatus(
        title: 'Finding your circle',
        message: 'Restoring your session…',
        showSpinner: true,
      ),
      error: (error, stack) => GateStatus(
        title: 'Could not restore your session',
        message: 'Check your connection, then try again.',
        onRetry: () => ref.invalidate(authSessionProvider),
      ),
    );
  }
}
