import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../application/telemetry_providers.dart';
import '../../domain/device_telemetry.dart';
import '../../domain/privacy_mode.dart';

/// The reason location sharing is not live, or null when it is.
typedef SharingNotice = ({String text, IconData icon});

SharingNotice? sharingNoticeFor(TelemetryState telemetry) {
  final permission = telemetry.permission;
  if (permission == null) return null;

  if (permission == TelemetryPermission.unsupported) {
    return (
      text: 'Live location is not available on this device',
      icon: Icons.location_disabled_rounded,
    );
  }
  if (permission != TelemetryPermission.granted) {
    return (
      text: 'Location is off — tap to start sharing',
      icon: Icons.location_off_rounded,
    );
  }
  if (telemetry.mode == PrivacyMode.paused) {
    return (
      text: 'Sharing paused — the crew sees battery only',
      icon: Icons.pause_circle_outline_rounded,
    );
  }
  return null;
}

class SharingNoticeBanner extends StatelessWidget {
  const SharingNoticeBanner({
    super.key,
    required this.notice,
    required this.onTap,
  });

  final SharingNotice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.tile);

    return Material(
      color: scheme.tertiaryContainer.withValues(alpha: 0.7),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Icon(notice.icon, size: 16, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notice.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: scheme.onTertiaryContainer),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.onTertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
