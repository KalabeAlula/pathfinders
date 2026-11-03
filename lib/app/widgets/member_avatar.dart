import 'package:flutter/material.dart';

import '../../features/circle/domain/user_profile.dart';

/// Generated initials avatar. Keeping avatars offline-first means the circle
/// still looks like itself before photos load or when a member is paused.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.profile,
    this.size = 40,
    this.isOnline = true,
    this.isPaused = false,
    this.isApproximate = false,
    this.showStatusBadge = true,
    this.badgeBorderColor,
  });

  final UserProfile profile;
  final double size;
  final bool isOnline;
  final bool isPaused;
  final bool isApproximate;
  final bool showStatusBadge;
  final Color? badgeBorderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Color(profile.avatarColor);
    final highlight = Color.lerp(base, Colors.white, 0.28) ?? base;
    final badgeBorder = badgeBorderColor ?? scheme.surfaceContainerLow;
    final badgeSize = size * 0.3;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [highlight, base],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: base.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              profile.initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          if (showStatusBadge)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? const Color(0xFF6F9E62) : scheme.outline,
                  border: Border.all(color: badgeBorder, width: 2),
                ),
              ),
            ),
          if (showStatusBadge && isPaused)
            Positioned(
              right: -2,
              top: -2,
              child: _StatusBadge(
                icon: Icons.visibility_off_rounded,
                backgroundColor: scheme.surfaceContainerHighest,
                iconColor: scheme.onSurfaceVariant,
                size: size * 0.4,
              ),
            ),
          if (showStatusBadge && isApproximate)
            Positioned(
              left: -2,
              top: -2,
              child: _StatusBadge(
                icon: Icons.blur_on_rounded,
                backgroundColor: scheme.surfaceContainerHighest,
                iconColor: scheme.onSurfaceVariant,
                size: size * 0.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.size,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
      child: Icon(icon, size: size * 0.62, color: iconColor),
    );
  }
}
