import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../nudges/domain/nudge.dart';
import '../../domain/circle_member.dart';
import '../../domain/group_type.dart';
import 'member_card.dart';

class MemberPresenceHeader extends StatelessWidget {
  const MemberPresenceHeader({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.now,
    required this.groupType,
    required this.onMemberTap,
    required this.onWarmth,
    required this.onWarmthOptions,
  });

  final List<CircleMember> members;
  final String currentUserId;
  final DateTime now;
  final GroupType groupType;
  final ValueChanged<CircleMember> onMemberTap;
  final ValueChanged<CircleMember> onWarmth;
  final ValueChanged<CircleMember> onWarmthOptions;

  @override
  Widget build(BuildContext context) {
    final quickEmoji = NudgeWarmth.defaultFor(groupType).emoji;
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final member = members[index];
          final isCurrentUser = member.profile.id == currentUserId;
          return MemberCard(
            member: member,
            isCurrentUser: isCurrentUser,
            now: now,
            onTap: () => onMemberTap(member),
            warmthEmoji: isCurrentUser ? null : quickEmoji,
            onWarmth: isCurrentUser ? null : () => onWarmth(member),
            onWarmthOptions: isCurrentUser
                ? null
                : () => onWarmthOptions(member),
          );
        },
      ),
    );
  }
}
