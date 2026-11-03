import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/member_avatar.dart';
import '../../../../core/utils/time_format.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../location/application/telemetry_providers.dart';
import '../../../location/domain/device_telemetry.dart';
import '../../../location/domain/privacy_mode.dart';
import '../../../location/presentation/widgets/background_location_disclosure.dart';
import '../../../nudges/application/nudge_providers.dart';
import '../../application/circle_providers.dart';
import '../../domain/circle_member.dart';
import '../member_status_label.dart';

typedef _SharingConfig = ({
  TelemetryPermission? permission,
  PrivacyMode mode,
  String? error,
  bool backgroundGranted,
  bool? notificationsGranted,
});

Future<void> _requestBackgroundSharing(
  BuildContext context,
  WidgetRef ref,
  String currentUserId,
) async {
  final confirmed = await showBackgroundLocationDisclosure(context);
  if (!confirmed || !context.mounted) return;
  await ref
      .read(telemetryControllerProvider(currentUserId).notifier)
      .requestBackgroundAccess();
}

Future<void> showMemberDetailSheet(
  BuildContext context, {
  required String memberId,
  required CircleMember initialMember,
  required bool isCurrentUser,
  required String currentUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MemberDetailSheet(
      memberId: memberId,
      initialMember: initialMember,
      isCurrentUser: isCurrentUser,
      currentUserId: currentUserId,
    ),
  );
}

class MemberDetailSheet extends ConsumerWidget {
  const MemberDetailSheet({
    super.key,
    required this.memberId,
    required this.initialMember,
    required this.isCurrentUser,
    required this.currentUserId,
  });

  final String memberId;
  final CircleMember initialMember;
  final bool isCurrentUser;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(circleSnapshotProvider(currentUserId)).value;
    final member = snapshot?.memberById(memberId) ?? initialMember;
    final status = member.status;
    // The sharing controls depend on permission and mode, not on the fix
    // itself, so GPS ticks must not rebuild the sheet.
    final sharing = ref.watch(
      telemetryControllerProvider(currentUserId).select(
        (state) => (
          permission: state.permission,
          mode: state.mode,
          error: state.error,
          backgroundGranted: state.backgroundGranted,
          notificationsGranted: state.notificationsGranted,
        ),
      ),
    );
    final now = DateTime.now();
    final online = status?.isOnlineAt(now) ?? false;
    final scheme = Theme.of(context).colorScheme;
    final battery = status?.batteryPercent;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MemberAvatar(
                  profile: member.profile,
                  size: 58,
                  isOnline: online,
                  isPaused: status?.isPaused ?? false,
                  isApproximate: status?.isApproximate ?? false,
                  showStatusBadge: status != null,
                  badgeBorderColor: scheme.surfaceContainerLow,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.profile.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            _YouPill(color: scheme.secondaryContainer),
                          ],
                        ],
                      ),
                      if (member.profile.statusLine != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          member.profile.statusLine!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: status?.isPaused ?? false
                        ? Icons.visibility_off_rounded
                        : Icons.place_rounded,
                    label: 'Now',
                    value: describeMemberLocation(status, now),
                  ),
                  Divider(height: 20, color: scheme.outlineVariant),
                  _InfoRow(
                    icon: status?.isCharging ?? false
                        ? Icons.battery_charging_full_rounded
                        : Icons.battery_5_bar_rounded,
                    label: 'Battery',
                    value: battery == null
                        ? '—'
                        : '$battery%${status!.isCharging ? ' · charging' : ''}',
                    valueColor: battery != null && battery <= 20
                        ? scheme.error
                        : null,
                  ),
                  Divider(height: 20, color: scheme.outlineVariant),
                  _InfoRow(
                    icon: Icons.sync_rounded,
                    label: 'Update',
                    value: status == null
                        ? '—'
                        : online
                        ? 'Live · ${timeAgo(status.updatedAt)}'
                        : 'Offline · ${timeAgo(status.updatedAt)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isCurrentUser) ...[
              _SharingSection(
                state: sharing,
                onModeChanged: (mode) => unawaited(
                  ref
                      .read(telemetryControllerProvider(currentUserId).notifier)
                      .setMode(mode),
                ),
                onRequestAccess: () => unawaited(
                  ref
                      .read(telemetryControllerProvider(currentUserId).notifier)
                      .requestAccess(),
                ),
                onAppSettings: () => unawaited(
                  ref
                      .read(telemetryControllerProvider(currentUserId).notifier)
                      .openAppSettings(),
                ),
                onLocationSettings: () => unawaited(
                  ref
                      .read(telemetryControllerProvider(currentUserId).notifier)
                      .openLocationSettings(),
                ),
                onEnableBackground: () => unawaited(
                  _requestBackgroundSharing(context, ref, currentUserId),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await ref.read(authRepositoryProvider).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                ),
              ),
            ] else ...[
              _InfoRow(
                icon: Icons.shield_outlined,
                label: 'Sharing',
                value: status == null
                    ? 'Not sharing yet'
                    : _privacyLabel(status.privacyMode),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () async {
                    final controller = ref.read(
                      nudgeControllerProvider.notifier,
                    );
                    Navigator.of(context).pop();
                    await controller.sendNudge(
                      fromUserId: currentUserId,
                      recipientIds: [memberId],
                    );
                  },
                  icon: const Icon(Icons.wifi_tethering_rounded, size: 20),
                  label: Text('Send ${member.profile.firstName} a nudge'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _privacyLabel(PrivacyMode? mode) => switch (mode) {
    PrivacyMode.exact => 'Exact location',
    PrivacyMode.approximate => 'Approximate area',
    PrivacyMode.paused => 'Paused',
    null => '—',
  };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: valueColor ?? scheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class _SharingSection extends StatelessWidget {
  const _SharingSection({
    required this.state,
    required this.onModeChanged,
    required this.onRequestAccess,
    required this.onAppSettings,
    required this.onLocationSettings,
    required this.onEnableBackground,
  });

  final _SharingConfig state;
  final ValueChanged<PrivacyMode> onModeChanged;
  final VoidCallback onRequestAccess;
  final VoidCallback onAppSettings;
  final VoidCallback onLocationSettings;
  final VoidCallback onEnableBackground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final permission = state.permission;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location sharing',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 3),
        Text(
          'You decide how much the crew sees. Battery stays visible for safety.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (permission != null &&
            permission != TelemetryPermission.granted) ...[
          const SizedBox(height: 12),
          _PermissionNotice(
            permission: permission,
            onRequestAccess: onRequestAccess,
            onAppSettings: onAppSettings,
            onLocationSettings: onLocationSettings,
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 10),
          Text(
            state.error!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: 12),
        for (final mode in PrivacyMode.values) ...[
          _PrivacyOption(
            mode: mode,
            selected: mode == state.mode,
            onTap: () => onModeChanged(mode),
          ),
          if (mode != PrivacyMode.values.last) const SizedBox(height: 8),
        ],
        if (permission == TelemetryPermission.granted && !kIsWeb) ...[
          const SizedBox(height: 12),
          _BackgroundSharingTile(state: state, onEnable: onEnableBackground),
        ],
      ],
    );
  }
}

class _BackgroundSharingTile extends StatelessWidget {
  const _BackgroundSharingTile({required this.state, required this.onEnable});

  final _SharingConfig state;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final granted = state.backgroundGranted;

    final subtitle = switch ((granted, state.mode)) {
      (false, _) => 'Off — your crew only sees you while the app is open.',
      (true, PrivacyMode.paused) =>
        'On — picks up again when you resume sharing.',
      (true, _) => 'On — keeps updating until you pause, even off-screen.',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              granted ? Icons.smartphone_rounded : Icons.phone_iphone_rounded,
              size: 20,
              color: granted ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sharing with the app closed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (granted && state.notificationsGranted == false) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notifications are off, so Android will not show that '
                    'sharing is running.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!granted)
            TextButton(
              onPressed: onEnable,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Turn on'),
            ),
        ],
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({
    required this.permission,
    required this.onRequestAccess,
    required this.onAppSettings,
    required this.onLocationSettings,
  });

  final TelemetryPermission permission;
  final VoidCallback onRequestAccess;
  final VoidCallback onAppSettings;
  final VoidCallback onLocationSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, message, action, onAction) = switch (permission) {
      TelemetryPermission.denied => (
        Icons.location_off_rounded,
        'Location is off for Pathfinders. Allow it so your crew can see '
            'where you are.',
        'Turn on',
        onRequestAccess,
      ),
      TelemetryPermission.deniedForever => (
        Icons.lock_outline_rounded,
        'Location is blocked. Enable it for Pathfinders in system settings.',
        'Open settings',
        onAppSettings,
      ),
      TelemetryPermission.servicesDisabled => (
        Icons.location_disabled_rounded,
        'Location services are off. Turn them on to share where you are.',
        'Open settings',
        onLocationSettings,
      ),
      _ => (
        Icons.info_outline_rounded,
        'Live location is not available on this device.',
        null,
        null,
      ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: scheme.onTertiaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onTertiaryContainer),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(action),
            ),
        ],
      ),
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  const _PrivacyOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final PrivacyMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.tile);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: radius,
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.65)
              : Colors.transparent,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  mode.icon,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        mode.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer.withValues(
                                  alpha: 0.75,
                                )
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YouPill extends StatelessWidget {
  const _YouPill({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'you',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontSize: 10,
        ),
      ),
    );
  }
}

extension on PrivacyMode {
  String get label => switch (this) {
    PrivacyMode.exact => 'Exact pin',
    PrivacyMode.approximate => 'Approximate area',
    PrivacyMode.paused => 'Paused',
  };

  String get description => switch (this) {
    PrivacyMode.exact => 'Show your live position on the map.',
    PrivacyMode.approximate =>
      'Share a soft area; your exact street stays private.',
    PrivacyMode.paused =>
      'Share no location until you turn it back on. Battery stays visible.',
  };

  IconData get icon => switch (this) {
    PrivacyMode.exact => Icons.my_location_rounded,
    PrivacyMode.approximate => Icons.blur_on_rounded,
    PrivacyMode.paused => Icons.pause_circle_outline_rounded,
  };
}
