import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../domain/group_type.dart';

/// Compact label for a group kind. With [showIcon] it becomes the header's
/// type indicator; with [onTap] it doubles as the way into circle details.
class GroupTypeBadge extends StatelessWidget {
  const GroupTypeBadge({
    super.key,
    required this.type,
    this.showIcon = false,
    this.onTap,
  });

  final GroupType type;
  final bool showIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: showIcon ? 9 : 7,
        vertical: showIcon ? 5 : 2,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              groupTypeIcon(type),
              size: 13,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            type.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontSize: showIcon ? 9 : 8.5,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;
    return Tooltip(
      message: 'Group details',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('group-type-pill'),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: pill,
        ),
      ),
    );
  }
}

IconData groupTypeIcon(GroupType type) => switch (type) {
  GroupType.couple => Icons.favorite_rounded,
  GroupType.friends => Icons.groups_rounded,
  GroupType.family => Icons.home_rounded,
};
