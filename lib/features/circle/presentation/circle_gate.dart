import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/main_shell_screen.dart';
import '../../../app/widgets/onboarding_shell.dart';
import '../../auth/application/auth_providers.dart';
import '../../location/application/telemetry_providers.dart';
import '../application/circle_providers.dart';
import '../domain/circle_failure.dart';
import 'circle_onboarding_screen.dart';

/// Shows circle setup until the signed-in user belongs to a circle.
class CircleGate extends ConsumerWidget {
  const CircleGate({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(circlesProvider(userId));
    // Keep sharing alive for the whole signed-in session. This gate stays
    // mounted under pushed screens, whereas watching telemetry from individual
    // widgets would let auto-dispose stop the heartbeat on navigation.
    ref.listen(telemetryControllerProvider(userId), (_, _) {});
    ref.listen(circleMembershipNoticeProvider, (_, notice) {
      if (notice == null) return;
      ref.read(circleMembershipNoticeProvider.notifier).clear();
      // A removed member may have a detail screen or sheet on top.
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("You're no longer in $notice.")));
    });

    if (circles.hasError && !circles.hasValue) {
      return _errorStatus(ref, circles.error!, () {
        ref.invalidate(circlesProvider(userId));
        ref.invalidate(circleSnapshotProvider(userId));
      });
    }

    if (!circles.hasValue) {
      return const GateStatus(title: 'Opening your circles', showSpinner: true);
    }

    if (circles.requireValue.isEmpty) {
      return CircleOnboardingScreen(userId: userId);
    }

    final snapshot = ref.watch(circleSnapshotProvider(userId));
    return snapshot.when(
      data: (value) => value == null
          ? const GateStatus(title: 'Opening your group', showSpinner: true)
          : MainShellScreen(snapshot: value, currentUserId: userId),
      loading: () =>
          const GateStatus(title: 'Opening your group', showSpinner: true),
      error: (error, stack) => _errorStatus(ref, error, () {
        ref.invalidate(circleSnapshotProvider(userId));
      }),
    );
  }

  Widget _errorStatus(WidgetRef ref, Object error, VoidCallback onRetry) {
    final message = error is CircleFailure
        ? error.message
        : 'Could not load your circle.';
    return GateStatus(
      title: 'Your circle is out of reach',
      message: message,
      onRetry: onRetry,
      footer: TextButton(
        onPressed: () async {
          await ref.read(authRepositoryProvider).signOut();
        },
        child: const Text('Sign out'),
      ),
    );
  }
}
