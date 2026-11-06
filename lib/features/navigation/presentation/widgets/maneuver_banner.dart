import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/navigation_maneuver.dart';
import '../../domain/route_step.dart';

/// Material symbol for a Directions maneuver.
IconData maneuverIcon(ManeuverKind kind) => switch (kind) {
  ManeuverKind.depart => Icons.navigation_rounded,
  ManeuverKind.turnLeft => Icons.turn_left_rounded,
  ManeuverKind.turnRight => Icons.turn_right_rounded,
  ManeuverKind.slightLeft => Icons.turn_slight_left_rounded,
  ManeuverKind.slightRight => Icons.turn_slight_right_rounded,
  ManeuverKind.sharpLeft => Icons.turn_sharp_left_rounded,
  ManeuverKind.sharpRight => Icons.turn_sharp_right_rounded,
  ManeuverKind.uTurn => Icons.u_turn_left_rounded,
  ManeuverKind.straight => Icons.straight_rounded,
  ManeuverKind.roundabout => Icons.roundabout_left_rounded,
  ManeuverKind.merge => Icons.merge_rounded,
  ManeuverKind.forkLeft => Icons.fork_left_rounded,
  ManeuverKind.forkRight => Icons.fork_right_rounded,
  ManeuverKind.rampLeft => Icons.ramp_left_rounded,
  ManeuverKind.rampRight => Icons.ramp_right_rounded,
  ManeuverKind.arrive => Icons.flag_rounded,
};

/// "Then turn right onto Africa Ave" for the preview line.
String? followingManeuverText(RouteStep? step) {
  if (step == null) return null;
  final instruction = step.instruction;
  if (instruction.isEmpty) return null;
  return 'Then ${instruction[0].toLowerCase()}${instruction.substring(1)}';
}

/// Google Maps-style header shown while a trip is active.
///
/// The banner sits over the map at the very top of the screen, so it owns the
/// status-bar inset itself. It stays dark green in both themes because it must
/// out-shout bright streets underneath.
class ManeuverBanner extends StatelessWidget {
  const ManeuverBanner({
    super.key,
    required this.maneuver,
    this.onChat,
    this.unreadChats = 0,
  });

  final NavigationManeuver maneuver;
  final VoidCallback? onChat;
  final int unreadChats;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final road = maneuver.next.roadName.trim();
    final preview = followingManeuverText(maneuver.following);

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.forestDeep, AppColors.forest],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  maneuverIcon(maneuver.next.kind),
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatManeuverDistance(maneuver.distanceMeters),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineSmall?.copyWith(
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      road.isEmpty ? maneuver.next.instruction : road,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 13,
                            color: AppColors.mint.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelMedium?.copyWith(
                                color: AppColors.mint.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onChat != null) ...[
                const SizedBox(width: 8),
                _ChatButton(onPressed: onChat!, unread: unreadChats),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.onPressed, required this.unread});

  final VoidCallback onPressed;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      tooltip: 'Open group chat',
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        foregroundColor: Colors.white,
        fixedSize: const Size(42, 42),
      ),
      icon: const Icon(Icons.forum_rounded, size: 20),
    );

    if (unread <= 0) return button;
    return Badge.count(
      count: unread,
      backgroundColor: AppColors.mint,
      textColor: AppColors.forest,
      child: button,
    );
  }
}
