import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../domain/group_type.dart';

class GroupTypeBadge extends StatelessWidget {
  const GroupTypeBadge({super.key, required this.type});

  final GroupType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        type.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimaryContainer,
          fontSize: 8.5,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
