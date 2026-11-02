import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/onboarding_shell.dart';
import '../../auth/application/auth_providers.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
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
    final snapshot = ref.watch(circleSnapshotProvider(userId));
    // Keep sharing alive for the whole signed-in session. This gate stays
    // mounted under pushed screens, whereas watching telemetry from individual
    // widgets would let auto-dispose stop the heartbeat on navigation.
    ref.listen(telemetryControllerProvider(userId), (_, _) {});

    return snapshot.when(
      data: (value) => value == null
          ? CircleOnboardingScreen(userId: userId)
          : DashboardScreen(snapshot: value, currentUserId: userId),
      loading: () =>
          const GateStatus(title: 'Opening your circle', showSpinner: true),
      error: (error, stack) {
        final message = error is CircleFailure
            ? error.message
            : 'Could not load your circle.';
        return GateStatus(
          title: 'Your circle is out of reach',
          message: message,
          onRetry: () => ref.invalidate(circleSnapshotProvider(userId)),
          footer: TextButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            child: const Text('Sign out'),
          ),
        );
      },
    );
  }
}
