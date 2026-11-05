import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../chat/presentation/widgets/chat_badge_button.dart';
import '../../../circle/domain/group_type.dart';
import '../../../circle/presentation/widgets/group_type_badge.dart';
import '../../../pet/domain/ethiopian_pet.dart';
import '../../../pet/presentation/widgets/pet_avatar.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.firstName,
    required this.circleName,
    required this.dateLine,
    required this.unreadCount,
    required this.onChat,
    this.type,
    this.memberCount,
    this.memberCapacity,
    this.pet,
    this.petName,
    this.onOpenGroups,
    this.onOpenPet,
    this.onOpenSettings,
  });

  final String greeting;
  final String firstName;
  final String circleName;
  final String dateLine;
  final int unreadCount;
  final VoidCallback onChat;
  final GroupType? type;
  final int? memberCount;
  final int? memberCapacity;
  final EthiopianPet? pet;
  final String? petName;
  final VoidCallback? onOpenGroups;
  final VoidCallback? onOpenPet;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final memberLine = memberCount == null
        ? null
        : memberCapacity == null
        ? (memberCount == 1 ? '1 member' : '$memberCount members')
        : '$memberCount of $memberCapacity members';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 1),
              Text(firstName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 3),
              if (onOpenGroups == null)
                Text(
                  '$circleName · $dateLine',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                )
              else ...[
                Row(
                  children: [
                    if (pet != null) ...[
                      Tooltip(
                        message: 'Meet ${petName ?? pet!.commonName}',
                        child: GestureDetector(
                          onTap: onOpenPet,
                          child: PetAvatar(pet: pet!, size: 22),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Tooltip(
                        message: 'Switch group',
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            onTap: onOpenGroups,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      circleName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  memberLine == null ? dateLine : '$memberLine · $dateLine',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerLow,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ChatBadgeButton(unreadCount: unreadCount, onTap: onChat),
          ),
        ),
        if (type != null) ...[
          const SizedBox(width: 8),
          GroupTypeBadge(type: type!, showIcon: true, onTap: onOpenSettings),
        ],
      ],
    );
  }
}
